///|
fn normalize_persisted_record(
  schema : ModelSchema,
  current : Record?,
  row : Record,
) -> Record {
  apply_schema_timestamps(
    schema,
    current,
    apply_column_defaults(schema, merge_record_payload(current, row)),
  )
}

///|
fn merge_record_payload(current : Record?, row : Record) -> Record {
  match current {
    Some(existing) =>
      record(row.table, merge_record_fields(existing.fields, row.fields))
    None => row
  }
}

///|
fn apply_column_defaults(schema : ModelSchema, row : Record) -> Record {
  let mut fields = clone_record_fields(row.fields)
  for column in schema.columns {
    if @support.find_entry(fields, column.name) is None {
      match column.default_value {
        Some(value) => fields = put_record_field(fields, column.name, value)
        None => ()
      }
    }
  }
  record(row.table, fields)
}

///|
fn apply_schema_timestamps(
  schema : ModelSchema,
  current : Record?,
  row : Record,
) -> Record {
  if not(schema.timestamps) {
    return row
  }
  let mut fields = clone_record_fields(row.fields)
  if current is None && @support.find_entry(fields, "created_at") is None {
    fields = put_record_field(fields, "created_at", "CURRENT_TIMESTAMP")
  }
  if @support.find_entry(fields, "updated_at") is None || current is Some(_) {
    fields = put_record_field(fields, "updated_at", "CURRENT_TIMESTAMP")
  }
  record(row.table, fields)
}

///|
fn merge_record_fields(
  base_fields : Array[(String, String)],
  override_fields : Array[(String, String)],
) -> Array[(String, String)] {
  let mut merged = clone_record_fields(base_fields)
  for field in override_fields {
    merged = put_record_field(merged, field.0, field.1)
  }
  merged
}

///|
fn clone_record_fields(
  fields : Array[(String, String)],
) -> Array[(String, String)] {
  @support.clone_array(fields)
}

///|
fn put_record_field(
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
