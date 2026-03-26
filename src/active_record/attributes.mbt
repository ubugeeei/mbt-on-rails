///|
/// Represents one typed attribute value derived from a schema column.
pub enum AttributeValue {
  StringAttribute(String)
  IntegerAttribute(Int)
  BooleanAttribute(Bool)
  TimestampAttribute(String)
  JsonAttribute(String)
  NullAttribute
} derive(Eq, Show)

///|
/// Stores one typed field in stable record order.
pub struct TypedField {
  name : String
  value : AttributeValue
} derive(Eq, Show)

///|
/// Stores one typed record payload produced from a string-backed record.
pub struct TypedRecord {
  table : String
  fields : Array[TypedField]
} derive(Eq, Show)

///|
/// Describes one type-casting failure while mapping record fields to a schema.
pub struct AttributeCastError {
  attribute : String
  expected_type : String
  value : String?
  detail : String
} derive(Eq, Show)

///|
/// Represents the result of casting one string-backed record.
pub enum CastRecordOutcome {
  CastedRecord(TypedRecord)
  CastRecordFailed(Array[AttributeCastError])
} derive(Eq, Show)

///|
/// Represents the result of rendering one typed JSON document from a record.
pub enum SerializeRecordOutcome {
  SerializedRecordJson(String)
  SerializeRecordFailed(Array[AttributeCastError])
} derive(Eq, Show)

///|
pub fn CastRecordOutcome::typed_record(
  self : CastRecordOutcome,
) -> TypedRecord? {
  match self {
    CastedRecord(current) => Some(current)
    CastRecordFailed(_) => None
  }
}

///|
pub fn CastRecordOutcome::errors(
  self : CastRecordOutcome,
) -> Array[AttributeCastError] {
  match self {
    CastedRecord(_) => []
    CastRecordFailed(errors) => errors
  }
}

///|
pub fn SerializeRecordOutcome::json(self : SerializeRecordOutcome) -> String? {
  match self {
    SerializedRecordJson(json) => Some(json)
    SerializeRecordFailed(_) => None
  }
}

///|
pub fn SerializeRecordOutcome::errors(
  self : SerializeRecordOutcome,
) -> Array[AttributeCastError] {
  match self {
    SerializedRecordJson(_) => []
    SerializeRecordFailed(errors) => errors
  }
}

///|
pub fn typed_field(name : String, value : AttributeValue) -> TypedField {
  { name, value }
}

///|
pub fn typed_record(table : String, fields : Array[TypedField]) -> TypedRecord {
  { table, fields }
}

///|
pub fn attribute_cast_error(
  attribute : String,
  expected_type : String,
  value : String?,
  detail : String,
) -> AttributeCastError {
  { attribute, expected_type, value, detail }
}

///|
pub fn attribute_type_name(column : Column) -> String {
  let base = match column.column_type {
    Varchar => "String"
    Text => "String"
    Integer => "Int"
    Boolean => "Bool"
    Timestamp => "String"
    Json => "Json"
    References(_) => "Int"
  }
  if column.nullable {
    base + "?"
  } else {
    base
  }
}

///|
pub fn AttributeValue::record_value(self : AttributeValue) -> String? {
  match self {
    StringAttribute(value) => Some(value)
    IntegerAttribute(value) => Some(value.to_string())
    BooleanAttribute(value) => Some(if value { "true" } else { "false" })
    TimestampAttribute(value) => Some(value)
    JsonAttribute(value) => Some(value)
    NullAttribute => None
  }
}

///|
pub fn AttributeValue::json_value(self : AttributeValue) -> String {
  match self {
    StringAttribute(value) => @support.json_string(value)
    IntegerAttribute(value) => value.to_string()
    BooleanAttribute(value) => if value { "true" } else { "false" }
    TimestampAttribute(value) => @support.json_string(value)
    JsonAttribute(value) => json_attribute_literal(value)
    NullAttribute => "null"
  }
}

///|
pub fn TypedRecord::to_record(self : TypedRecord) -> Record {
  let fields : Array[(String, String)] = []
  for field in self.fields {
    match field.value.record_value() {
      Some(value) => fields.push((field.name, value))
      None => ()
    }
  }
  record(self.table, fields)
}

///|
pub fn TypedRecord::to_json(self : TypedRecord) -> String {
  let parts : Array[String] = []
  for field in self.fields {
    parts.push(
      @support.json_string(field.name) + ": " + field.value.json_value(),
    )
  }
  "{" + parts.join(", ") + "}"
}

///|
pub fn AttributeCastError::message(self : AttributeCastError) -> String {
  let rendered_value = match self.value {
    Some(value) => value
    None => "<missing>"
  }
  self.attribute +
  " expected " +
  self.expected_type +
  " but got " +
  rendered_value +
  " (" +
  self.detail +
  ")"
}

///|
fn json_attribute_literal(source : String) -> String {
  let trimmed = source.trim().to_string()
  if trimmed.length() == 0 {
    return @support.json_string("")
  }
  if trimmed.has_prefix("{") || trimmed.has_prefix("[") {
    return trimmed
  }
  if trimmed.has_prefix("\"") && trimmed.has_suffix("\"") {
    return trimmed
  }
  if trimmed == "true" || trimmed == "false" || trimmed == "null" {
    return trimmed
  }
  if @support.is_numeric_literal(trimmed) {
    return trimmed
  }
  @support.json_string(source)
}
