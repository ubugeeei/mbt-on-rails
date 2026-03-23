///|
/// Builds the demo `User` model schema.
pub fn demo_user_model() -> @orm.ModelSchema {
  @orm.with_validation(
    @orm.with_validation(
      @orm.with_validation(
        @orm.model(
          "User",
          "users",
          [
            @orm.unique(@orm.indexed(@orm.string_column("email"))),
            @orm.string_column("password_digest"),
            @orm.with_default(@orm.string_column("role"), "user"),
            @orm.nullable(@orm.string_column("display_name")),
          ],
          true,
          false,
        ),
        @orm.validates_presence("email"),
      ),
      @orm.validates_uniqueness("email"),
    ),
    @orm.validates_format("email", "@"),
  )
}

///|
/// Builds the demo `Session` model schema.
pub fn demo_session_model() -> @orm.ModelSchema {
  @orm.with_association(
    @orm.model(
      "Session",
      "sessions",
      [
        @orm.references_column("user_id", "users"),
        @orm.unique(@orm.string_column("csrf_token")),
        @orm.timestamp_column("expires_at"),
        @orm.json_column("meta"),
      ],
      true,
      false,
    ),
    @orm.belongs_to("user", "User", "user_id"),
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
  @orm.with_callback(
    @orm.with_association(
      @orm.with_association(
        @orm.with_validation(
          @orm.with_validation(
            post_scaffold.model,
            @orm.validates_presence("body"),
          ),
          @orm.validates_uniqueness("slug"),
        ),
        @orm.belongs_to("author", "User", "author_id"),
      ),
      @orm.has_many("comments", "Comment", "post_id"),
    ),
    @orm.before_validation("slugify_title"),
  )
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
