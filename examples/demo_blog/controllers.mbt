///|
/// Builds the controller serving the demo home page.
pub fn demo_pages_controller() -> @controller.ControllerDefinition {
  @controller.controller_named("PagesController").with_action(
    @controller.action_plan("home").render_page("home"),
  )
}

///|
/// Builds the controller handling demo session routes.
pub fn demo_sessions_controller() -> @controller.ControllerDefinition {
  @controller.controller_named("SessionsController")
  .for_resource("sessions")
  .with_before_action(
    @controller.before_only("new").requiring(@auth.auth_guest_only()),
  )
  .with_before_action(
    @controller.before_only("create")
    .requiring(@auth.auth_guest_only())
    .permitting(["email", "password"]),
  )
  .with_action(
    @controller.action_plan("new")
    .require_auth(@auth.auth_guest_only())
    .render_page("sign_in"),
  )
  .with_action(
    @controller.action_plan("create")
    .require_auth(@auth.auth_guest_only())
    .permit_params(["email", "password"])
    .invoke_server_action("sessions.create")
    .deliver_mail("SessionMailer.welcome")
    .touch_cache("session")
    .flash("notice", "welcome")
    .redirect_to("/")
    .json()
    .as_mutation()
    .as_transactional(),
  )
  .with_action(
    @controller.action_plan("destroy")
    .require_auth(@auth.auth_required())
    .invoke_server_action("sessions.destroy")
    .touch_cache("session")
    .redirect_to("/")
    .as_mutation(),
  )
}

///|
/// Builds the route table for the demo app.
pub fn demo_routes(post_controller_name : String) -> Array[@http.RouteSpec] {
  let routes : Array[@http.RouteSpec] = [
    @http.route(
      name="home",
      verb=@http.http_get(),
      path="/",
      controller="PagesController",
      action="home",
      page_name=Some("home"),
    ),
    @http.route(
      name="sign_in",
      verb=@http.http_get(),
      path="/sign-in",
      controller="SessionsController",
      action="new",
      page_name=Some("sign_in"),
    ),
    @http.route(
      name="sign_out",
      verb=@http.http_delete(),
      path="/sign-out",
      controller="SessionsController",
      action="destroy",
      page_name=None,
    ),
  ]
  for
    generated in @http.resources(
      "posts",
      post_controller_name,
      @http.default_resource_options("posts", Some("posts")).with_member_action(
        "publish",
        @http.http_post(),
      ),
    ) {
    routes.push(generated)
  }
  routes
}
