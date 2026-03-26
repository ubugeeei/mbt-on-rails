///|
test "orm migration example builders keep relation migration and validation stable" {
  let schema = post_model()
  assert_eq(schema.associations.length(), 1)
  assert_eq(schema.associations[0].name, "author")
  assert_eq(schema.callbacks[0].hook.to_string(), "BeforeValidation")

  let relation = @mbor.limit_to(
    @mbor.order_by(
      @mbor.where_like(
        @mbor.where_eq(@mbor.relation_for(schema), "author_id", "7"),
        "title",
        "%MoonBit%",
      ),
      "created_at",
      descending=true,
    ),
    5,
  )
  assert_eq(
    @mbor.relation_to_sql(relation),
    "SELECT * FROM posts WHERE author_id = 7 AND title LIKE '%MoonBit%' ORDER BY created_at DESC LIMIT 5",
  )

  let migration = @mbor.migration_from_model(
    "20260323040201", "create_posts", schema,
  )
  let down_sql = @mbor.migration_down_sql(migration)
  assert_true(
    @mbor.migration_up_sql(migration)[0].contains("CREATE TABLE posts"),
  )
  assert_true(down_sql.contains("DROP INDEX idx_posts_slug"))
  assert_true(down_sql.contains("DROP INDEX idx_posts_author_id"))
  assert_eq(down_sql[down_sql.length() - 1], "DROP TABLE posts")

  let phased = publish_backfill_migration()
  let constraints = validate_post_constraints_migration()
  let phased_up = @mbor.migration_up_sql(phased)
  let phased_down = @mbor.migration_down_sql(phased)
  let constraint_up = @mbor.migration_up_sql(constraints)
  assert_true(@mbor.migration_safe(phased))
  assert_eq(@mbor.migration_risk_level(phased).to_string(), "Safe")
  assert_true(
    @mbor.migration_safety_summary(phased).contains(
      "backfill_post_published [safe]",
    ),
  )
  assert_true(
    phased_up.contains(
      "ALTER TABLE posts ALTER COLUMN published SET DEFAULT 'false'",
    ),
  )
  assert_true(
    phased_up.contains(
      "UPDATE posts SET published = 'false' WHERE published IS NULL",
    ),
  )
  assert_eq(phased_down[0], "DROP INDEX CONCURRENTLY idx_posts_published")
  assert_true(@mbor.migration_safe(constraints))
  assert_true(
    constraint_up.contains(
      "ALTER TABLE posts ADD CONSTRAINT posts_slug_present CHECK (slug <> '') NOT VALID",
    ),
  )
  assert_true(
    constraint_up.contains(
      "ALTER TABLE posts VALIDATE CONSTRAINT fk_posts_author_id",
    ),
  )

  let casted = @mbor.cast_record(schema, typed_post_row())
  match casted.typed_record() {
    Some(current) => {
      assert_eq(current.fields.length(), 6)
      assert_true(current.to_json().contains("\"author_id\": 7"))
    }
    None => assert_true(false)
  }
  let serialized = @mbor.serialize_record_json(
    schema,
    @mbor.record("posts", [("author_id", "oops")]),
  )
  assert_eq(serialized.json(), None)
  let errors = serialized.errors()
  assert_eq(errors.length(), 1)
  assert_true(
    errors[0].message().contains("author_id expected Int but got oops"),
  )

  let db = @mbor.insert_record(
    @mbor.empty_memory_database(),
    @mbor.record("posts", [("slug", "first-post")]),
  )
  let invalid = @mbor.record("posts", [("title", ""), ("slug", "first-post")])
  let errors = @mbor.validate_record(schema, invalid, db)
  assert_true(errors.contains("title must be present"))
  assert_true(errors.contains("slug must be unique"))
}

///|
test "orm migration example print helpers and main smoke stay runnable" {
  let schema = post_model()
  print_relation_example(schema)
  print_migration_example(schema)
  print_typed_attribute_example(schema)
  print_memory_example(schema)
  run_example()
  assert_true(true)
}
