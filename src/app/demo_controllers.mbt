///|
/// Builds the controller serving the demo home page.
pub fn demo_pages_controller() -> @controller.ControllerDefinition {
  @controller.controller("PagesController", None, "application", [], [
    @controller.action(
      "home",
      [@controller.render_page_step("home")],
      Some("home"),
      false,
      [],
      [@controller.html_format()],
      false,
    ),
  ])
}

///|
/// Builds the controller handling demo session routes.
pub fn demo_sessions_controller() -> @controller.ControllerDefinition {
  @controller.controller(
    "SessionsController",
    Some("sessions"),
    "application",
    [
      @controller.before_action(Some("new"), Some(@auth.auth_guest_only()), []),
      @controller.before_action(Some("create"), Some(@auth.auth_guest_only()), [
        "email", "password",
      ]),
    ],
    [
      @controller.action(
        "new",
        [
          @controller.require_auth(@auth.auth_guest_only()),
          @controller.render_page_step("sign_in"),
        ],
        Some("sign_in"),
        false,
        [],
        [@controller.html_format()],
        false,
      ),
      @controller.action(
        "create",
        [
          @controller.require_auth(@auth.auth_guest_only()),
          @controller.invoke_server_action_step("sessions.create"),
          @controller.flash("notice", "welcome"),
          @controller.redirect_to_step("/"),
        ],
        None,
        true,
        ["email", "password"],
        [@controller.redirect_format(), @controller.json_format()],
        true,
      ),
      @controller.action(
        "destroy",
        [
          @controller.require_auth(@auth.auth_required()),
          @controller.invoke_server_action_step("sessions.destroy"),
          @controller.redirect_to_step("/"),
        ],
        None,
        true,
        [],
        [@controller.redirect_format()],
        false,
      ),
    ],
  )
}

///|
/// Builds the route table for the demo app.
pub fn demo_routes(post_controller_name : String) -> Array[@http.RouteSpec] {
  let routes : Array[@http.RouteSpec] = [
    @http.route(
      "home",
      @http.http_get(),
      "/",
      "PagesController",
      "home",
      Some("home"),
    ),
    @http.route(
      "sign_in",
      @http.http_get(),
      "/sign-in",
      "SessionsController",
      "new",
      Some("sign_in"),
    ),
    @http.route(
      "sign_out",
      @http.http_delete(),
      "/sign-out",
      "SessionsController",
      "destroy",
      None,
    ),
  ]
  for
    generated in @http.resources(
      "posts",
      post_controller_name,
      @http.with_member_action(
        @http.default_resource_options("posts", Some("posts")),
        "publish",
        @http.http_post(),
      ),
    ) {
    routes.push(generated)
  }
  routes
}
