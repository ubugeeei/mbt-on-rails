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
      true,
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
  print_memory_example(schema)
  run_example()
  assert_true(true)
}
