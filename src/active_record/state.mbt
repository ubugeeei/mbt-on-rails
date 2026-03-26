///|
/// Describes one changed attribute between two record snapshots.
pub struct DirtyFieldChange {
  attribute : String
  before : String?
  after : String?
}

///|
/// Tracks the current and original state of one record payload.
pub struct DirtyRecord {
  table : String
  original_fields : Array[(String, String)]
  current_fields : Array[(String, String)]
  changes : Array[DirtyFieldChange]
}

///|
/// Stores one named snapshot inside an in-memory transaction.
pub struct TransactionSavepoint {
  name : String
  database : MemoryDatabase
}

///|
/// Represents one in-memory transaction plus optional savepoints.
pub struct MemoryTransaction {
  original_database : MemoryDatabase
  database : MemoryDatabase
  savepoints : Array[TransactionSavepoint]
}

///|
/// Represents the result of saving a record inside a transaction.
pub enum TransactionSaveOutcome {
  TransactionSaved(MemoryTransaction, Record)
  TransactionValidationFailed(MemoryTransaction, ValidationErrors)
}

///|
/// Builds a dirty-tracked record from an original and current snapshot.
pub fn dirty_record(original : Record, current : Record) -> DirtyRecord {
  let original_fields = @support.clone_array(original.fields)
  let current_fields = @support.clone_array(current.fields)
  {
    table: current.table,
    original_fields,
    current_fields,
    changes: diff_record_fields(original_fields, current_fields),
  }
}

///|
/// Builds a dirty-tracked record for a new unsaved row.
pub fn dirty_new_record(row : Record) -> DirtyRecord {
  dirty_record(record(row.table, []), row)
}

///|
/// Returns whether any attribute changed between the two snapshots.
pub fn DirtyRecord::changed(self : DirtyRecord) -> Bool {
  not(self.changes.is_empty())
}

///|
/// Returns the names of the changed attributes in stable field order.
pub fn DirtyRecord::changed_fields(self : DirtyRecord) -> Array[String] {
  let fields : Array[String] = []
  for change in self.changes {
    fields.push(change.attribute)
  }
  fields
}

///|
/// Returns one attribute change if present.
pub fn DirtyRecord::change_for(
  self : DirtyRecord,
  attribute : String,
) -> DirtyFieldChange? {
  for change in self.changes {
    if change.attribute == attribute {
      return Some(change)
    }
  }
  None
}

///|
/// Returns whether one specific attribute changed.
pub fn DirtyRecord::attribute_changed(
  self : DirtyRecord,
  attribute : String,
) -> Bool {
  match self.change_for(attribute) {
    Some(_) => true
    None => false
  }
}

///|
/// Returns the attribute value from the original snapshot.
pub fn DirtyRecord::attribute_was(
  self : DirtyRecord,
  attribute : String,
) -> String? {
  match self.change_for(attribute) {
    Some(change) => change.before
    None => @support.find_entry(self.original_fields, attribute)
  }
}

///|
/// Returns the current record payload represented by the dirty state.
pub fn DirtyRecord::apply(self : DirtyRecord) -> Record {
  record(self.table, @support.clone_array(self.current_fields))
}

///|
/// Marks the current snapshot as persisted and clears dirty state.
pub fn DirtyRecord::clear_changes_information(
  self : DirtyRecord,
) -> DirtyRecord {
  let current_fields = @support.clone_array(self.current_fields)
  {
    table: self.table,
    original_fields: current_fields,
    current_fields,
    changes: [],
  }
}

///|
/// Renders one dirty summary line per changed attribute.
pub fn DirtyRecord::changes_summary(self : DirtyRecord) -> String {
  let lines : Array[String] = []
  for change in self.changes {
    lines.push(
      change.attribute +
      ": " +
      display_change_value(change.before) +
      " -> " +
      display_change_value(change.after),
    )
  }
  lines.join(", ")
}

///|
/// Chainable alias for `dirty_record`.
pub fn Record::track_changes(self : Record, current : Record) -> DirtyRecord {
  dirty_record(self, current)
}

///|
/// Starts one in-memory transaction from the supplied database state.
pub fn begin_transaction(db : MemoryDatabase) -> MemoryTransaction {
  { original_database: db, database: db, savepoints: [] }
}

///|
/// Chainable alias for `begin_transaction`.
pub fn MemoryDatabase::begin_transaction(
  self : MemoryDatabase,
) -> MemoryTransaction {
  begin_transaction(self)
}

///|
/// Adds one named savepoint for the current transaction state.
pub fn create_savepoint(
  transaction : MemoryTransaction,
  name : String,
) -> MemoryTransaction {
  let savepoints = @support.clone_array(transaction.savepoints)
  savepoints.push({ name, database: transaction.database })
  { ..transaction, savepoints, }
}

///|
/// Inserts one row into the transaction-local database snapshot.
pub fn transaction_insert(
  transaction : MemoryTransaction,
  row : Record,
) -> MemoryTransaction {
  { ..transaction, database: insert_record(transaction.database, row) }
}

///|
/// Validates and saves one row into the transaction-local database snapshot.
pub fn transaction_save(
  schema : ModelSchema,
  transaction : MemoryTransaction,
  row : Record,
) -> TransactionSaveOutcome {
  match save_record(schema, transaction.database, row) {
    Saved(database, saved) =>
      TransactionSaved({ ..transaction, database, }, saved)
    ValidationFailed(errors) => TransactionValidationFailed(transaction, errors)
  }
}

///|
/// Restores the transaction-local database to the named savepoint.
pub fn rollback_to_savepoint(
  transaction : MemoryTransaction,
  name : String,
) -> MemoryTransaction {
  let mut index = transaction.savepoints.length()
  while index > 0 {
    index -= 1
    if transaction.savepoints[index].name == name {
      let savepoints : Array[TransactionSavepoint] = []
      for current in 0..<(index + 1) {
        savepoints.push(transaction.savepoints[current])
      }
      return {
        ..transaction,
        database: transaction.savepoints[index].database,
        savepoints,
      }
    }
  }
  transaction
}

///|
/// Returns the committed database snapshot for the transaction.
pub fn commit_transaction(transaction : MemoryTransaction) -> MemoryDatabase {
  transaction.database
}

///|
/// Returns the original database snapshot before the transaction started.
pub fn rollback_transaction(transaction : MemoryTransaction) -> MemoryDatabase {
  transaction.original_database
}

///|
/// Returns records from the current transaction-local database snapshot.
pub fn MemoryTransaction::find_records(
  self : MemoryTransaction,
  table_name : String,
  column_name : String,
  value : String,
) -> Array[Record] {
  find_records(self.database, table_name, column_name, value)
}

///|
/// Chainable alias for `create_savepoint`.
pub fn MemoryTransaction::savepoint(
  self : MemoryTransaction,
  name : String,
) -> MemoryTransaction {
  create_savepoint(self, name)
}

///|
/// Chainable alias for `transaction_insert`.
pub fn MemoryTransaction::insert(
  self : MemoryTransaction,
  row : Record,
) -> MemoryTransaction {
  transaction_insert(self, row)
}

///|
/// Chainable alias for `transaction_save`.
pub fn MemoryTransaction::save(
  self : MemoryTransaction,
  schema : ModelSchema,
  row : Record,
) -> TransactionSaveOutcome {
  transaction_save(schema, self, row)
}

///|
/// Chainable alias for `rollback_to_savepoint`.
pub fn MemoryTransaction::rollback_to(
  self : MemoryTransaction,
  name : String,
) -> MemoryTransaction {
  rollback_to_savepoint(self, name)
}

///|
/// Chainable alias for `commit_transaction`.
pub fn MemoryTransaction::commit(self : MemoryTransaction) -> MemoryDatabase {
  commit_transaction(self)
}

///|
/// Chainable alias for `rollback_transaction`.
pub fn MemoryTransaction::rollback(self : MemoryTransaction) -> MemoryDatabase {
  rollback_transaction(self)
}

///|
fn diff_record_fields(
  original : Array[(String, String)],
  current : Array[(String, String)],
) -> Array[DirtyFieldChange] {
  let changes : Array[DirtyFieldChange] = []
  for attribute in ordered_field_names(original, current) {
    let before = @support.find_entry(original, attribute)
    let after = @support.find_entry(current, attribute)
    if not(optional_string_eq(before, after)) {
      changes.push({ attribute, before, after })
    }
  }
  changes
}

///|
fn ordered_field_names(
  original : Array[(String, String)],
  current : Array[(String, String)],
) -> Array[String] {
  let names : Array[String] = []
  for field in original {
    if not(names.contains(field.0)) {
      names.push(field.0)
    }
  }
  for field in current {
    if not(names.contains(field.0)) {
      names.push(field.0)
    }
  }
  names
}

///|
fn optional_string_eq(left : String?, right : String?) -> Bool {
  match left {
    Some(left_value) =>
      match right {
        Some(right_value) => left_value == right_value
        None => false
      }
    None =>
      match right {
        Some(_) => false
        None => true
      }
  }
}

///|
fn display_change_value(value : String?) -> String {
  match value {
    Some(current) => current
    None => "<unset>"
  }
}
