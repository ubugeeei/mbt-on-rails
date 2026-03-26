///|
fn attribute_schema() -> ModelSchema {
  model(
    name="Post",
    table="posts",
    columns=[
      string_column("title"),
      integer_column("views"),
      boolean_column("published"),
      json_column("meta"),
      references_column("author_id", "users"),
    ],
    soft_delete=true,
  )
}

///|
test "cast_record maps schema-backed fields into typed values" {
  let schema = attribute_schema()
  let row = record("posts", [
    ("id", "1"),
    ("title", "Launch"),
    ("views", "42"),
    ("published", "true"),
    ("meta", "{\"tags\":[\"moonbit\"]}"),
    ("author_id", "7"),
    ("created_at", "2026-03-27T00:00:00Z"),
    ("deleted_at", "null"),
  ])

  match cast_record(schema, row) {
    CastedRecord(current) => {
      assert_eq(current.fields.length(), 8)
      assert_eq(attribute_type_name(integer_column("views")), "Int")
      assert_eq(
        attribute_type_name(nullable(boolean_column("published"))),
        "Bool?",
      )
      match current.fields[0].value {
        IntegerAttribute(value) => assert_eq(value, 1)
        _ => assert_true(false)
      }
      match current.fields[3].value {
        BooleanAttribute(value) => assert_true(value)
        _ => assert_true(false)
      }
      match current.fields[4].value {
        JsonAttribute(value) => assert_true(value.contains("\"moonbit\""))
        _ => assert_true(false)
      }
      match current.fields[7].value {
        NullAttribute => assert_true(true)
        _ => assert_true(false)
      }
      let roundtrip = current.to_record()
      assert_eq(find_entry(roundtrip.fields, "views"), Some("42"))
      assert_eq(find_entry(roundtrip.fields, "published"), Some("true"))
      assert_eq(find_entry(roundtrip.fields, "deleted_at"), None)
    }
    CastRecordFailed(_) => assert_true(false)
  }
}

///|
test "serialize_record_json emits typed JSON and surfaces cast failures" {
  let schema = attribute_schema()
  let valid = record("posts", [
    ("id", "1"),
    ("title", "Launch"),
    ("views", "42"),
    ("published", "false"),
    ("meta", "{\"tags\":[\"moonbit\"]}"),
    ("author_id", "7"),
    ("updated_at", "2026-03-27T00:00:00Z"),
  ])
  match serialize_record_json(schema, valid) {
    SerializedRecordJson(json) => {
      assert_true(json.contains("\"id\": 1"))
      assert_true(json.contains("\"published\": false"))
      assert_true(json.contains("\"meta\": {\"tags\":[\"moonbit\"]}"))
      assert_true(json.contains("\"updated_at\": \"2026-03-27T00:00:00Z\""))
    }
    SerializeRecordFailed(_) => assert_true(false)
  }

  let invalid = record("posts", [
    ("views", "forty-two"),
    ("published", "maybe"),
    ("author_id", "abc"),
    ("unknown_field", "surprise"),
  ])
  match serialize_record_json(schema, invalid) {
    SerializedRecordJson(_) => assert_true(false)
    SerializeRecordFailed(errors) => {
      assert_eq(errors.length(), 4)
      assert_true(
        errors[0].message().contains("views expected Int but got forty-two"),
      )
      assert_true(
        errors[1].message().contains("published expected Bool but got maybe"),
      )
      assert_true(
        errors[2].message().contains("author_id expected Int but got abc"),
      )
      assert_true(
        errors[3].message().contains("unknown_field expected KnownAttribute"),
      )
    }
  }
}
