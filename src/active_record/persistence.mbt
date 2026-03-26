///|
/// Represents the result of validating and saving a record.
pub enum SaveOutcome {
  Saved(MemoryDatabase, Record)
  ValidationFailed(ValidationErrors)
}

///|
/// Represents the result of destroying one persisted record.
pub enum DestroyOutcome {
  DestroyedRecord(MemoryDatabase, Record)
  DestroyNotFound(MemoryDatabase)
}

///|
/// Finds one record by the model's configured primary key.
pub fn find_record_by_primary_key(
  schema : ModelSchema,
  db : MemoryDatabase,
  value : String,
) -> Record? {
  for table in db.tables {
    if table.name != schema.table {
      continue
    }
    for row in table.rows {
      if record_matches_primary_key(row, schema.primary_key, value) {
        return Some(row)
      }
    }
  }
  None
}

///|
/// Validates and persists a record, updating the current row when the primary key matches.
pub fn save_record(
  schema : ModelSchema,
  db : MemoryDatabase,
  row : Record,
) -> SaveOutcome {
  let current = resolve_current_record(schema, db, row)
  let candidate = merge_persisted_record(current, row)
  let errors = validate_record_errors(schema, candidate, db)
  if not(errors.is_empty()) {
    return ValidationFailed(errors)
  }
  Saved(write_record(schema, db, candidate), candidate)
}

///|
/// Destroys one record by primary key, respecting soft-delete models.
pub fn destroy_record(
  schema : ModelSchema,
  db : MemoryDatabase,
  value : String,
  deleted_at? : String? = None,
) -> DestroyOutcome {
  match find_record_by_primary_key(schema, db, value) {
    Some(current) =>
      if schema.soft_delete {
        let tombstone = soft_delete_record(current, deleted_at)
        DestroyedRecord(write_record(schema, db, tombstone), tombstone)
      } else {
        DestroyedRecord(remove_record(schema, db, value), current)
      }
    None => DestroyNotFound(db)
  }
}

///|
pub fn MemoryDatabase::find_record_by_primary_key(
  self : MemoryDatabase,
  schema : ModelSchema,
  value : String,
) -> Record? {
  find_record_by_primary_key(schema, self, value)
}

///|
pub fn MemoryDatabase::destroy(
  self : MemoryDatabase,
  schema : ModelSchema,
  value : String,
  deleted_at? : String? = None,
) -> DestroyOutcome {
  destroy_record(schema, self, value, deleted_at~)
}

///|
fn resolve_current_record(
  schema : ModelSchema,
  db : MemoryDatabase,
  row : Record,
) -> Record? {
  match @support.find_entry(row.fields, schema.primary_key) {
    Some(value) => find_record_by_primary_key(schema, db, value)
    None => None
  }
}

///|
fn merge_persisted_record(current : Record?, row : Record) -> Record {
  match current {
    Some(existing) =>
      record(row.table, merge_fields(existing.fields, row.fields))
    None => row
  }
}

///|
fn write_record(
  schema : ModelSchema,
  db : MemoryDatabase,
  row : Record,
) -> MemoryDatabase {
  match @support.find_entry(row.fields, schema.primary_key) {
    Some(value) =>
      upsert_record_by_primary_key(
        db,
        row,
        schema.table,
        schema.primary_key,
        value,
      )
    None => insert_record(db, row)
  }
}

///|
fn upsert_record_by_primary_key(
  db : MemoryDatabase,
  row : Record,
  table_name : String,
  primary_key : String,
  primary_key_value : String,
) -> MemoryDatabase {
  let tables : Array[MemoryTable] = []
  let mut replaced = false
  let mut table_found = false
  for table in db.tables {
    if table.name != table_name {
      tables.push(table)
      continue
    }
    table_found = true
    let rows : Array[Record] = []
    for current in table.rows {
      if record_matches_primary_key(current, primary_key, primary_key_value) {
        rows.push(row)
        replaced = true
      } else {
        rows.push(current)
      }
    }
    if not(replaced) {
      rows.push(row)
    }
    tables.push({ name: table.name, rows })
  }
  if not(table_found) {
    tables.push({ name: table_name, rows: [row] })
  }
  { tables, }
}

///|
fn remove_record(
  schema : ModelSchema,
  db : MemoryDatabase,
  value : String,
) -> MemoryDatabase {
  let tables : Array[MemoryTable] = []
  for table in db.tables {
    if table.name != schema.table {
      tables.push(table)
      continue
    }
    let rows : Array[Record] = []
    for current in table.rows {
      if not(record_matches_primary_key(current, schema.primary_key, value)) {
        rows.push(current)
      }
    }
    tables.push({ name: table.name, rows })
  }
  { tables, }
}

///|
fn soft_delete_record(row : Record, deleted_at : String?) -> Record {
  record(
    row.table,
    merge_fields(row.fields, [
      (
        "deleted_at",
        match deleted_at {
          Some(timestamp) => timestamp
          None => "CURRENT_TIMESTAMP"
        },
      ),
    ]),
  )
}

///|
fn merge_fields(
  base_fields : Array[(String, String)],
  override_fields : Array[(String, String)],
) -> Array[(String, String)] {
  let mut merged = @support.clone_array(base_fields)
  for field in override_fields {
    merged = set_field(merged, field.0, field.1)
  }
  merged
}

///|
fn set_field(
  fields : Array[(String, String)],
  name : String,
  value : String,
) -> Array[(String, String)] {
  let next : Array[(String, String)] = []
  let mut replaced = false
  for field in fields {
    if field.0 == name {
      next.push((name, value))
      replaced = true
    } else {
      next.push(field)
    }
  }
  if not(replaced) {
    next.push((name, value))
  }
  next
}

///|
fn record_matches_primary_key(
  row : Record,
  primary_key : String,
  value : String,
) -> Bool {
  match @support.find_entry(row.fields, primary_key) {
    Some(current) => current == value
    None => false
  }
}
