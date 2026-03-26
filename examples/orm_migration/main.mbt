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
/// Prints in-memory relation execution for the same query shape.
fn print_relation_execution_example(model : @mbor.ModelSchema) -> Unit {
  let db = @mbor.empty_memory_database()
    .insert_record(
      @mbor.record("posts", [
        ("id", "1"),
        ("title", "MoonBit Launch"),
        ("slug", "moonbit-launch"),
        ("body", "Shipping MoonBit on Rails"),
        ("author_id", "7"),
      ]),
    )
    .insert_record(
      @mbor.record("posts", [
        ("id", "2"),
        ("title", "Rails Notes"),
        ("slug", "rails-notes"),
        ("body", "Operational notes"),
        ("author_id", "8"),
      ]),
    )
  let relation = @mbor.relation_for(model)
    .where_eq("author_id", "7")
    .where_like("title", "%MoonBit%")
    .select_columns(["id", "title"])

  println("Relation Execution")
  let outcome = relation.execute(model, db)
  println("count = " + outcome.count().to_string())
  match outcome.first() {
    Some(row) => {
      let title = match @mbor.find_entry(row.fields, "title") {
        Some(value) => value
        None => "missing"
      }
      println("first title = " + title)
    }
    None => println("first title = missing")
  }
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
/// Builds one schema-shaped row used to demonstrate typed casting helpers.
fn typed_post_row() -> @mbor.Record {
  @mbor.record("posts", [
    ("id", "42"),
    ("title", "MoonBit on Rails"),
    ("body", "Typed attributes keep transport explicit."),
    ("author_id", "7"),
    ("created_at", "2026-03-27T00:00:00Z"),
    ("updated_at", "2026-03-27T00:05:00Z"),
  ])
}

///|
/// Prints typed attribute casting and error reporting for one schema-backed row.
fn print_typed_attribute_example(model : @mbor.ModelSchema) -> Unit {
  println("Typed Attributes")
  let casted = typed_post_row().cast(model)
  match casted.typed_record() {
    Some(current) => {
      println(
        "author_id type = " +
        @mbor.references_column("author_id", "users").attribute_type_name(),
      )
      println(current.to_json())
    }
    None =>
      for error in casted.errors() {
        println("- " + error.message())
      }
  }
  println("")
  println("Typed Attribute Error")
  let serialized = @mbor.record("posts", [("author_id", "oops")]).serialize_json(
    model,
  )
  match serialized.json() {
    Some(json) => println(json)
    None =>
      for error in serialized.errors() {
        println("- " + error.message())
      }
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
  print_relation_execution_example(model)
  println("")
  print_migration_example(model)
  println("")
  print_typed_attribute_example(model)
  println("")
  print_memory_example(model)
}

///|
fn main {
  run_example()
}
