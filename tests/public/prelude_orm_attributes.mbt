///|
/// Extra ORM typed-attribute exports kept separate so the shared prelude stays split up.
pub using @mbor {
  type AttributeCastError,
  type AttributeValue,
  type CastRecordOutcome,
  type SerializeRecordOutcome,
  type TypedField,
  type TypedRecord,
  attribute_cast_error,
  attribute_type_name,
  cast_record,
  find_column,
  serialize_record_json,
  typed_field,
  typed_record,
}
