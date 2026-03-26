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
      default_resource_options("posts", Some("posts"))
      .with_member_action("publish", http_post())
      .with_collection_action("search", http_get()),
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
  let user_model = model(name="User", table="users", columns=[
      string_column("email").indexed().unique(),
      string_column("password"),
      string_column("password_confirmation"),
    ])
    .with_validation(validates_presence(field="email"))
    .with_validation(validates_uniqueness(field="email"))
    .with_validation(
      validates_confirmation(
        field="password",
        confirmation_field="password_confirmation",
      ),
    )

  let relation = relation_for(user_model)
    .where_eq("email", "hello@example.com")
    .order_by("created_at", true)
    .limit_to(10)
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
  let user_model = model(name="User", table="users", columns=[
    string_column("email").indexed().unique(),
    string_column("password_digest"),
  ])

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

///|
test "declarative controller and app builders preserve inferred metadata" {
  let controller = controller_named("SessionsController")
    .for_resource("sessions")
    .with_before_action(
      before_only("create")
      .requiring(auth_guest_only())
      .permitting(["email", "password"]),
    )
    .with_action(
      action_plan("create")
      .require_auth(auth_guest_only())
      .permit_params(["email", "password"])
      .invoke_server_action("sessions.create")
      .redirect_to("/")
      .json()
      .as_mutation()
      .as_transactional(),
    )

  match controller_action(controller, "create") {
    Some(action) => {
      assert_eq(action.page_name, None)
      assert_true(action.mutation)
      assert_true(action.transactional)
      assert_eq(action.allowed_params, ["email", "password"])
      assert_eq(action.formats.length(), 2)
    }
    None => assert_true(false)
  }

  let app = app_named("demo")
    .with_controller(controller)
    .with_route(
      route(
        "sign_in",
        http_get(),
        "/sign-in",
        "SessionsController",
        "create",
        None,
      ),
    )
  assert_eq(app.controllers.length(), 1)
  assert_eq(app.routes.length(), 1)
}

///|
test "restful controller can derive strong params for arbitrary resources" {
  let controller = restful_controller_with_params("comments", "comments", [
    "body", "post_id",
  ])

  match controller_action(controller, "create") {
    Some(action) => {
      assert_eq(action.allowed_params, ["body", "post_id"])
      assert_eq(action.steps.length(), 8)
    }
    None => assert_true(false)
  }
}
