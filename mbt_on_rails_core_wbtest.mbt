///|
test "support helpers keep json and paths stable" {
  assert_eq(normalize_path("posts/42/"), "/posts/42")
  assert_eq(
    entries_to_json([("id", "42"), ("published", "true")]),
    "{\"id\": 42, \"published\": true}",
  )
}

///|
test "resources and namespace routes recognize member and collection actions" {
  let routes = namespace_routes(
    "admin",
    resources(
      "posts",
      "Admin::PostsController",
      with_collection_action(
        with_member_action(
          default_resource_options("posts", Some("posts")),
          "publish",
          http_post(),
        ),
        "search",
        http_get(),
      ),
    ),
  )

  assert_eq(routes.length(), 9)

  let publish_request = request(
    http_post(),
    "/admin/posts/42/publish",
    [],
    [],
    None,
    "",
  )
  match recognize(routes, publish_request) {
    Some(matched) => {
      assert_eq(matched.route.name, "admin_posts_publish")
      assert_eq(matched.route.controller, "Admin::PostsController")
      assert_eq(matched.params[0].0, "id")
      assert_eq(matched.params[0].1, "42")
    }
    None => assert_true(false)
  }

  let search_request = request(
    http_get(),
    "/admin/posts/search",
    [],
    [],
    None,
    "",
  )
  match recognize(routes, search_request) {
    Some(matched) => {
      assert_eq(matched.route.name, "admin_posts_search")
      assert_eq(matched.route.action, "search")
    }
    None => assert_true(false)
  }
}

///|
test "active record relation and validation cover rails-like basics" {
  let user_model = with_validation(
    with_validation(
      with_validation(
        model(
          "User",
          "users",
          [
            unique(indexed(string_column("email"))),
            string_column("password"),
            string_column("password_confirmation"),
          ],
          true,
          false,
        ),
        validates_presence("email"),
      ),
      validates_uniqueness("email"),
    ),
    validates_confirmation("password", "password_confirmation"),
  )

  let relation = limit_to(
    order_by(
      where_eq(relation_for(user_model), "email", "hello@example.com"),
      "created_at",
      true,
    ),
    10,
  )
  assert_eq(
    relation_to_sql(relation),
    "SELECT * FROM users WHERE email = 'hello@example.com' ORDER BY created_at DESC LIMIT 10",
  )

  let db = insert_record(
    empty_memory_database(),
    record("users", [
      ("email", "hello@example.com"),
      ("password", "secret"),
      ("password_confirmation", "secret"),
    ]),
  )
  let invalid = record("users", [
    ("email", "hello@example.com"),
    ("password", "secret"),
    ("password_confirmation", "different"),
  ])
  let errors = validate_record(user_model, invalid, db)

  assert_true(errors.contains("email must be unique"))
  assert_true(errors.contains("password confirmation does not match"))
}

///|
test "migration generation produces reversible down sql" {
  let user_model = model(
    "User",
    "users",
    [unique(indexed(string_column("email"))), string_column("password_digest")],
    true,
    false,
  )

  let create_users = migration_from_model(
    "20260323010101", "create_users", user_model,
  )
  let up_sql = migration_sql(create_users)
  let down_sql = migration_down_sql(create_users)

  assert_true(up_sql[0].contains("CREATE TABLE users"))
  assert_true(up_sql[1].contains("CREATE UNIQUE INDEX idx_users_email"))
  assert_eq(down_sql[0], "DROP INDEX idx_users_email")
  assert_eq(down_sql[1], "DROP TABLE users")
}

///|
test "auth enforces roles and permissions" {
  let user = identity(
    "1",
    "hello@example.com",
    "editor",
    ["posts.publish"],
    None,
  )

  assert_true(authorize(Some(user), auth_required()))
  assert_true(authorize(Some(user), permission_access("posts.publish")))
  assert_false(authorize(Some(user), role_access("admin")))
}
