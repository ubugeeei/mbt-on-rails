///|
/// Holds the rows stored for one table in the in-memory adapter.
pub struct MemoryTable {
  name : String
  rows : Array[Record]
}

///|
/// Holds all tables stored by the in-memory adapter.
pub struct MemoryDatabase {
  tables : Array[MemoryTable]
}

///|
/// Represents the result of validating and saving a record.
pub enum SaveOutcome {
  Saved(MemoryDatabase, Record)
  ValidationFailed(Array[String])
}

///|
/// Returns an empty in-memory database.
pub fn empty_memory_database() -> MemoryDatabase {
  { tables: [] }
}

///|
/// Inserts a record into the in-memory database.
pub fn insert_record(db : MemoryDatabase, row : Record) -> MemoryDatabase {
  let tables : Array[MemoryTable] = []
  let mut inserted = false
  for table in db.tables {
    if table.name == row.table {
      let rows = @support.clone_array(table.rows)
      rows.push(row)
      tables.push({ name: table.name, rows })
      inserted = true
    } else {
      tables.push(table)
    }
  }
  if not(inserted) {
    tables.push({ name: row.table, rows: [row] })
  }
  { tables, }
}

///|
/// Finds records in the in-memory adapter by exact field value.
pub fn find_records(
  db : MemoryDatabase,
  table_name : String,
  column_name : String,
  value : String,
) -> Array[Record] {
  for table in db.tables {
    if table.name == table_name {
      let rows : Array[Record] = []
      for row in table.rows {
        match @support.find_entry(row.fields, column_name) {
          Some(current_value) => if current_value == value { rows.push(row) }
          None => ()
        }
      }
      return rows
    }
  }
  []
}

///|
/// Validates a record against a schema using the in-memory adapter.
pub fn validate_record(
  schema : ModelSchema,
  row : Record,
  db : MemoryDatabase,
) -> Array[String] {
  let errors : Array[String] = []
  for validation in schema.validations {
    let field_value = @support.find_entry(row.fields, validation.field)
    match validation.rule {
      Presence =>
        match field_value {
          Some(value) =>
            if value.trim().to_string().length() == 0 {
              errors.push(validation.field + " must be present")
            }
          None => errors.push(validation.field + " must be present")
        }
      Uniqueness =>
        match field_value {
          Some(value) => {
            let existing = find_records(db, row.table, validation.field, value)
            if not(existing.is_empty()) {
              errors.push(validation.field + " must be unique")
            }
          }
          None => ()
        }
      LengthMin(min_) =>
        match field_value {
          Some(value) =>
            if value.length() < min_ {
              errors.push(
                validation.field + " must have length >= " + min_.to_string(),
              )
            }
          None => ()
        }
      LengthMax(max_) =>
        match field_value {
          Some(value) =>
            if value.length() > max_ {
              errors.push(
                validation.field + " must have length <= " + max_.to_string(),
              )
            }
          None => ()
        }
      Inclusion(values) =>
        match field_value {
          Some(value) =>
            if not(values.contains(value)) {
              errors.push(validation.field + " is not included in the list")
            }
          None => ()
        }
      Confirmation(other_field) =>
        match field_value {
          Some(left) =>
            match @support.find_entry(row.fields, other_field) {
              Some(right) =>
                if left != right {
                  errors.push(validation.field + " confirmation does not match")
                }
              None => ()
            }
          None => ()
        }
      Format(pattern) =>
        match field_value {
          Some(value) =>
            if not(value.contains(pattern)) {
              errors.push(validation.field + " has invalid format")
            }
          None => ()
        }
    }
  }
  errors
}

///|
/// Validates and inserts a record into the in-memory adapter.
pub fn save_record(
  schema : ModelSchema,
  db : MemoryDatabase,
  row : Record,
) -> SaveOutcome {
  let errors = validate_record(schema, row, db)
  if not(errors.is_empty()) {
    return ValidationFailed(errors)
  }
  Saved(insert_record(db, row), row)
}
