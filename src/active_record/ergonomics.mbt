///|
/// Method alias for `attribute_type_name`.
pub fn Column::attribute_type_name(self : Column) -> String {
  attribute_type_name(self)
}

///|
/// Method alias for `find_column`.
pub fn ModelSchema::find_column(
  self : ModelSchema,
  attribute : String,
) -> Column? {
  find_column(self, attribute)
}

///|
/// Method alias for `cast_record`.
pub fn Record::cast(self : Record, schema : ModelSchema) -> CastRecordOutcome {
  cast_record(schema, self)
}

///|
/// Method alias for `serialize_record_json`.
pub fn Record::serialize_json(
  self : Record,
  schema : ModelSchema,
) -> SerializeRecordOutcome {
  serialize_record_json(schema, self)
}

///|
/// Method alias for `execute_relation`.
pub fn Relation::execute(
  self : Relation,
  schema : ModelSchema,
  db : MemoryDatabase,
) -> RelationExecutionOutcome {
  execute_relation(schema, db, self)
}

///|
/// Finds one typed field by attribute name.
pub fn TypedRecord::field(
  self : TypedRecord,
  attribute : String,
) -> TypedField? {
  for field in self.fields {
    if field.name == attribute {
      return Some(field)
    }
  }
  None
}

///|
/// Returns one typed attribute value by attribute name.
pub fn TypedRecord::value_for(
  self : TypedRecord,
  attribute : String,
) -> AttributeValue? {
  match self.field(attribute) {
    Some(field) => Some(field.value)
    None => None
  }
}
