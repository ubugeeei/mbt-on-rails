///|
fn relation_execution_schema() -> ModelSchema {
  model(name="Post", table="posts", columns=[
    string_column("title"),
    integer_column("views"),
    boolean_column("published"),
    references_column("author_id", "users"),
  ])
}

///|
fn relation_execution_db() -> MemoryDatabase {
  empty_memory_database()
  .insert_record(
    record("posts", [
      ("id", "1"),
      ("title", "Hello Rails"),
      ("views", "5"),
      ("published", "true"),
      ("author_id", "7"),
    ]),
  )
  .insert_record(
    record("posts", [
      ("id", "2"),
      ("title", "MoonBit Launch"),
      ("views", "12"),
      ("published", "true"),
      ("author_id", "7"),
    ]),
  )
  .insert_record(
    record("posts", [
      ("id", "3"),
      ("title", "MoonBit Shipping"),
      ("views", "30"),
      ("published", "true"),
      ("author_id", "9"),
    ]),
  )
  .insert_record(
    record("posts", [
      ("id", "4"),
      ("title", "MoonBit Draft"),
      ("views", "50"),
      ("published", "false"),
      ("author_id", "9"),
    ]),
  )
  .insert_record(
    record("posts", [
      ("id", "5"),
      ("title", "MoonBit Launch"),
      ("views", "18"),
      ("published", "true"),
      ("author_id", "10"),
    ]),
  )
}

///|
test "execute_relation filters sorts projects distincts and windows in memory" {
  let schema = relation_execution_schema()
  let db = relation_execution_db()
  let relation = relation_for(schema)
    .where_eq("published", "true")
    .where_gt("views", "10")
    .where_like("title", "%MoonBit%")
    .order_by("views", descending=true)
    .select_columns(["posts.id", "title"])
    .limit_to(2)

  let outcome = relation.execute(schema, db)
  assert_true(outcome.issues().is_empty())
  assert_true(outcome.exists())
  assert_eq(outcome.count(), 2)
  match outcome.first() {
    Some(row) => {
      assert_eq(find_entry(row.fields, "id"), Some("3"))
      assert_eq(find_entry(row.fields, "title"), Some("MoonBit Shipping"))
    }
    None => assert_true(false)
  }
  let records = outcome.records()
  assert_eq(find_entry(records[1].fields, "id"), Some("5"))

  let distinct_titles = relation_for(schema)
    .where_eq("published", "true")
    .where_like("title", "%MoonBit%")
    .select_columns(["title"])
    .distinct_records()
    .order_by("title")
    .execute(schema, db)
  assert_eq(distinct_titles.count(), 2)
  assert_eq(
    find_entry(distinct_titles.records()[0].fields, "title"),
    Some("MoonBit Launch"),
  )
}

///|
test "execute_relation surfaces unsupported features as explicit issues" {
  let schema = relation_execution_schema()
  let db = relation_execution_db()
  let unsupported = relation_for(schema)
    .join_relation("INNER JOIN users ON users.id = posts.author_id")
    .preload("author")
    .group_by(["author_id"])
    .having_raw("COUNT(*) > 1")
    .where_raw("published = TRUE")
    .execute(schema, db)

  assert_eq(unsupported.records().length(), 0)
  assert_eq(unsupported.count(), 0)
  assert_true(not(unsupported.exists()))
  let issues = unsupported.issues()
  assert_eq(issues.length(), 5)
  assert_true(issues[0].message().contains("joins"))
  assert_true(issues[1].message().contains("group_by"))
  assert_true(issues[2].message().contains("having"))
  assert_true(issues[3].message().contains("preload"))
  assert_true(issues[4].message().contains("raw_predicate"))

  let none = none_relation(relation_for(schema).where_raw("broken = TRUE")).execute(
    schema, db,
  )
  assert_true(none.issues().is_empty())
  assert_eq(none.count(), 0)
}
