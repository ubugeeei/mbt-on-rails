///|
/// Finds one schema column by attribute name, including generated timestamp fields.
pub fn find_column(schema : ModelSchema, attribute : String) -> Column? {
  if attribute == schema.primary_key {
    return Some(integer_column(attribute))
  }
  if schema.timestamps &&
    (attribute == "created_at" || attribute == "updated_at") {
    return Some(timestamp_column(attribute))
  }
  if schema.soft_delete && attribute == "deleted_at" {
    return Some(nullable(timestamp_column(attribute)))
  }
  for column in schema.columns {
    if column.name == attribute {
      return Some(column)
    }
  }
  None
}

///|
/// Casts one string-backed record into typed attribute values using the schema.
pub fn cast_record(schema : ModelSchema, row : Record) -> CastRecordOutcome {
  let errors : Array[AttributeCastError] = []
  let fields : Array[TypedField] = []
  for field in row.fields {
    match find_column(schema, field.0) {
      Some(column) =>
        match cast_field(column, field.1) {
          Some(value) => fields.push(typed_field(field.0, value))
          None => errors.push(cast_error_for(column, field.0, field.1))
        }
      None =>
        errors.push(
          attribute_cast_error(
            field.0,
            "KnownAttribute",
            Some(field.1),
            "no schema column or generated attribute matches this field",
          ),
        )
    }
  }
  if errors.is_empty() {
    CastedRecord(typed_record(row.table, fields))
  } else {
    CastRecordFailed(errors)
  }
}

///|
/// Renders one schema-backed record as typed JSON.
pub fn serialize_record_json(
  schema : ModelSchema,
  row : Record,
) -> SerializeRecordOutcome {
  match cast_record(schema, row) {
    CastedRecord(current) => SerializedRecordJson(current.to_json())
    CastRecordFailed(errors) => SerializeRecordFailed(errors)
  }
}

///|
fn cast_field(column : Column, value : String) -> AttributeValue? {
  let normalized = value.trim().to_string()
  if column.nullable && normalized == "null" {
    return Some(NullAttribute)
  }
  match column.column_type {
    Varchar => Some(StringAttribute(value))
    Text => Some(StringAttribute(value))
    Integer =>
      match parse_integer_literal(normalized) {
        Some(parsed) => Some(IntegerAttribute(parsed))
        None => None
      }
    Boolean =>
      match parse_boolean_literal(normalized) {
        Some(parsed) => Some(BooleanAttribute(parsed))
        None => None
      }
    Timestamp => Some(TimestampAttribute(value))
    Json => Some(JsonAttribute(value))
    References(_) =>
      match parse_integer_literal(normalized) {
        Some(parsed) => Some(IntegerAttribute(parsed))
        None => None
      }
  }
}

///|
fn cast_error_for(
  column : Column,
  attribute : String,
  value : String,
) -> AttributeCastError {
  attribute_cast_error(
    attribute,
    attribute_type_name(column),
    Some(value),
    cast_error_detail(column),
  )
}

///|
fn cast_error_detail(column : Column) -> String {
  match column.column_type {
    Integer => "expected a base-10 integer literal"
    Boolean => "expected true/false/1/0"
    References(table) => "expected an integer id referencing " + table
    _ => "expected a value matching the schema column type"
  }
}

///|
fn parse_integer_literal(source : String) -> Int? {
  if source.length() == 0 {
    return None
  }
  let chars = source.to_array()
  let mut index = 0
  let mut negative = false
  if chars[0] == '-' {
    negative = true
    index = 1
  }
  if index >= chars.length() {
    return None
  }
  let mut value = 0
  while index < chars.length() {
    let ch = chars[index]
    if ch < '0' || ch > '9' {
      return None
    }
    value = value * 10 + (ch.to_int() - '0'.to_int())
    index += 1
  }
  Some(if negative { -value } else { value })
}

///|
fn parse_boolean_literal(source : String) -> Bool? {
  match source {
    "true" => Some(true)
    "false" => Some(false)
    "1" => Some(true)
    "0" => Some(false)
    _ => None
  }
}
