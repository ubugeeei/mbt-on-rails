///|
/// Builds a `Post` schema used for ORM and migration examples.
fn post_model() -> @mbor.ModelSchema {
  @mbor.model(name="Post", table="posts", columns=[
    @mbor.string_column("title"),
    @mbor.indexed(@mbor.string_column("slug")),
    @mbor.text_column("body"),
    @mbor.references_column("author_id", "users"),
  ])
  .with_validation(@mbor.validates_presence(field="title"))
  .with_validation(@mbor.validates_uniqueness(field="slug"))
  .with_association(
    @mbor.belongs_to(name="author", target="User", foreign_key="author_id"),
  )
  .with_callback(@mbor.before_validation("slugify_title"))
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
      descending=true,
    ),
    5,
  )

  println("Relation SQL")
  println(@mbor.relation_to_sql(relation))
}

///|
/// Builds a phased, deployment-safe migration example.
fn publish_backfill_migration() -> @mbor.Migration {
  @mbor.migration_plan("20260326030101", "backfill_post_published")
  .add_column("posts", @mbor.nullable(@mbor.boolean_column("published")))
  .change_default("posts", "published", None, Some("false"))
  .change_null("posts", "published", false, backfill_value=Some("false"))
  .add_index_concurrently("posts", "published", false)
}

///|
/// Builds a phased constraint-validation example for legacy tables.
fn validate_post_constraints_migration() -> @mbor.Migration {
  @mbor.migration_plan("20260326030102", "validate_post_constraints")
  .add_check_constraint(
    "posts",
    "posts_slug_present",
    "slug <> ''",
    validate=false,
  )
  .add_foreign_key(
    "posts",
    "author_id",
    "users",
    validate=false,
    on_delete=Some("RESTRICT"),
  )
  .validate_check_constraint("posts", "posts_slug_present")
  .validate_foreign_key("posts", "author_id", "users")
}

///|
/// Prints migration up/down SQL for the model.
fn print_migration_example(model : @mbor.ModelSchema) -> Unit {
  let create_posts = @mbor.migration_from_model(
    "20260323040201", "create_posts", model,
  )
  let phased = publish_backfill_migration()
  let constraints = validate_post_constraints_migration()

  println("Create Migration Up")
  for statement in @mbor.migration_up_sql(create_posts) {
    println(statement)
  }
  println("")
  println("Create Migration Down")
  for statement in @mbor.migration_down_sql(create_posts) {
    println(statement)
  }
  println("")
  println("Phased Migration Safety")
  println(@mbor.migration_safety_summary(phased))
  println("")
  println("Phased Migration Up")
  for statement in @mbor.migration_up_sql(phased) {
    println(statement)
  }
  println("")
  println("Phased Migration Down")
  for statement in @mbor.migration_down_sql(phased) {
    println(statement)
  }
  println("")
  println("Constraint Validation Safety")
  println(@mbor.migration_safety_summary(constraints))
  println("")
  println("Constraint Validation Up")
  for statement in @mbor.migration_up_sql(constraints) {
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
/// Runs the ORM and migration example output.
fn run_example() -> Unit {
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

///|
fn main {
  run_example()
}
