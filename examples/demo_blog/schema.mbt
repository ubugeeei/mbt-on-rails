///|
/// Builds the demo `User` model schema.
pub fn demo_user_model() -> @orm.ModelSchema {
  @orm.model(
    name="User",
    table="users",
    columns=[
      @orm.string_column("email").indexed().unique(),
      @orm.string_column("password_digest"),
      @orm.string_column("role").with_default("user"),
      @orm.string_column("display_name").nullable(),
    ],
  )
  .with_validation(@orm.validates_presence(field="email"))
  .with_validation(@orm.validates_uniqueness(field="email"))
  .with_validation(@orm.validates_format(field="email", pattern="@"))
}

///|
/// Builds the demo `Session` model schema.
pub fn demo_session_model() -> @orm.ModelSchema {
  @orm.model(
    name="Session",
    table="sessions",
    columns=[
      @orm.references_column("user_id", "users"),
      @orm.string_column("csrf_token").unique(),
      @orm.timestamp_column("expires_at"),
      @orm.json_column("meta"),
    ],
  ).with_association(
    @orm.belongs_to(name="user", target="User", foreign_key="user_id"),
  )
}

///|
/// Builds the scaffold plan used for the demo `Post` resource.
pub fn demo_post_scaffold() -> @generator.ScaffoldPlan {
  @generator.scaffold_resource("posts", [
    @generator.scaffold_field("title", @orm.string_column("title")),
    @generator.scaffold_field("slug", @orm.indexed(@orm.string_column("slug"))),
    @generator.scaffold_field("body", @orm.text_column("body")),
  ])
}

///|
/// Builds the demo `Post` model schema from its scaffold plan.
pub fn demo_post_model(
  post_scaffold : @generator.ScaffoldPlan,
) -> @orm.ModelSchema {
  post_scaffold.model
  .with_validation(@orm.validates_presence(field="body"))
  .with_validation(@orm.validates_uniqueness(field="slug"))
  .with_association(
    @orm.belongs_to(name="author", target="User", foreign_key="author_id"),
  )
  .with_association(
    @orm.has_many(name="comments", target="Comment", foreign_key="post_id"),
  )
  .with_callback(@orm.before_validation("slugify_title"))
}

///|
/// Builds the demo migration list.
pub fn demo_migrations(
  user_model : @orm.ModelSchema,
  session_model : @orm.ModelSchema,
  post_model : @orm.ModelSchema,
) -> Array[@migration.Migration] {
  [
    @migration.migration_from_model(
      "20260323020101", "create_users", user_model,
    ),
    @migration.migration_from_model(
      "20260323020102", "create_sessions", session_model,
    ),
    @migration.migration("20260323020103", "create_posts", [
      @migration.create_table_step(post_model),
      @migration.add_column_step(
        "posts",
        @orm.references_column("author_id", "users"),
      ),
      @migration.add_index_step("posts", "author_id", false),
      @migration.reversible_step(
        "UPDATE posts SET published = FALSE WHERE published IS NULL", "UPDATE posts SET published = NULL",
      ),
    ]),
  ]
}
