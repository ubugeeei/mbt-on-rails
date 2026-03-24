///|
/// Builds the integrated demo blog application.
pub fn demo_blog_app() -> MbtOnRailsApp {
  let auth = @auth.default_auth_config()
  let user_model = demo_user_model()
  let session_model = demo_session_model()
  let post_scaffold = demo_post_scaffold()
  let post_model = demo_post_model(post_scaffold)
  let models = [user_model, session_model, post_model]
  let migrations = demo_migrations(user_model, session_model, post_model)
  let middlewares = demo_middlewares()
  let fixtures = demo_fixtures()
  let seeds = demo_seeds()
  let job_queues = demo_job_queues()
  let mailers = demo_mailers()
  let caches = demo_caches()
  let controllers = [
    demo_pages_controller(),
    demo_sessions_controller(),
    post_scaffold.controller,
  ]
  let routes = demo_routes(post_scaffold.controller.name)
  let layout = demo_application_layout()
  let pages = demo_pages(layout)
  let server_actions = demo_server_actions()
  app(
    "mbt on rails demo",
    auth,
    models,
    migrations,
    middlewares,
    fixtures,
    seeds,
    job_queues,
    mailers,
    caches,
    controllers,
    routes,
    pages,
    server_actions,
    [post_scaffold],
  )
}
