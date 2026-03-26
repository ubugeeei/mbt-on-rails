///|
/// Builds the integrated demo blog application.
pub fn demo_blog_app() -> @app.MbtOnRailsApp {
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
  let cable_channels = demo_cable_channels()
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
  @app.app_named("mbt on rails demo")
  .with_auth(auth)
  .with_models(models)
  .with_migrations(migrations)
  .with_middlewares(middlewares)
  .with_fixtures(fixtures)
  .with_seeds(seeds)
  .with_cable_channels(cable_channels)
  .with_job_queues(job_queues)
  .with_mailers(mailers)
  .with_caches(caches)
  .with_controllers(controllers)
  .with_routes(routes)
  .with_pages(pages)
  .with_server_actions(server_actions)
  .with_scaffold(post_scaffold)
}
