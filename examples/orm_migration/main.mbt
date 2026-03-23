///|
/// Builds a `Post` schema used for ORM and migration examples.
fn post_model() -> @mbor.ModelSchema {
  @mbor.with_callback(
    @mbor.with_association(
      @mbor.with_validation(
        @mbor.with_validation(
          @mbor.model(
            "Post",
            "posts",
            [
              @mbor.string_column("title"),
              @mbor.indexed(@mbor.string_column("slug")),
              @mbor.text_column("body"),
              @mbor.references_column("author_id", "users"),
            ],
            true,
            false,
          ),
          @mbor.validates_presence("title"),
        ),
        @mbor.validates_uniqueness("slug"),
      ),
      @mbor.belongs_to("author", "User", "author_id"),
    ),
    @mbor.before_validation("slugify_title"),
  )
}

///|
/// Prints a query-builder example.
fn print_relation_example(model : @mbor.ModelSchema) -> Unit {
  let relation = @mbor.limit_to(
    @mbor.order_by(
      @mbor.where_like(
        @mbor.where_eq(@mbor.relation_for(model), "author_id", "7"),
        "title",
        "%MoonBit%",
      ),
      "created_at",
      true,
    ),
    5,
  )

  println("Relation SQL")
  println(@mbor.relation_to_sql(relation))
}

///|
/// Prints migration up/down SQL for the model.
fn print_migration_example(model : @mbor.ModelSchema) -> Unit {
  let migration = @mbor.migration_from_model(
    "20260323040201", "create_posts", model,
  )
  println("Migration Up")
  for statement in @mbor.migration_up_sql(migration) {
    println(statement)
  }
  println("")
  println("Migration Down")
  for statement in @mbor.migration_down_sql(migration) {
    println(statement)
  }
}

///|
/// Prints in-memory validation behavior for one invalid record.
fn print_memory_example(model : @mbor.ModelSchema) -> Unit {
  let db = @mbor.insert_record(
    @mbor.empty_memory_database(),
    @mbor.record("posts", [
      ("title", "First post"),
      ("slug", "first-post"),
      ("body", "Long enough body"),
      ("author_id", "7"),
    ]),
  )
  let invalid = @mbor.record("posts", [
    ("title", ""),
    ("slug", "first-post"),
    ("body", "short"),
    ("author_id", "7"),
  ])

  println("Validation Errors")
  for error in @mbor.validate_record(model, invalid, db) {
    println("- " + error)
  }
}

///|
fn main {
  let model = post_model()
  println("ORM + Migration Example")
  println("=======================")
  println("")
  print_relation_example(model)
  println("")
  print_migration_example(model)
  println("")
  print_memory_example(model)
}
