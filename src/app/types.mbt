///|
/// Collects the models, routes, pages, and actions that form an app.
pub struct MbtOnRailsApp {
  name : String
  auth : @auth.AuthConfig
  models : Array[@orm.ModelSchema]
  migrations : Array[@migration.Migration]
  middlewares : Array[@middleware.Middleware]
  fixtures : Array[@fixture.FixtureSet]
  seeds : Array[@fixture.SeedPlan]
  cable_channels : Array[@cable.CableChannel]
  job_queues : Array[@job.JobQueue]
  mailers : Array[@mailer.MailerDefinition]
  caches : Array[@cache.CacheStore]
  controllers : Array[@controller.ControllerDefinition]
  routes : Array[@http.RouteSpec]
  pages : Array[@view.PageModule]
  server_actions : Array[@view.ServerAction]
  scaffolds : Array[@generator.ScaffoldPlan]
}

///|
/// Builds an application descriptor from framework primitives.
pub fn app(
  name : String,
  auth : @auth.AuthConfig,
  models : Array[@orm.ModelSchema],
  migrations : Array[@migration.Migration],
  middlewares : Array[@middleware.Middleware],
  fixtures : Array[@fixture.FixtureSet],
  seeds : Array[@fixture.SeedPlan],
  cable_channels : Array[@cable.CableChannel],
  job_queues : Array[@job.JobQueue],
  mailers : Array[@mailer.MailerDefinition],
  caches : Array[@cache.CacheStore],
  controllers : Array[@controller.ControllerDefinition],
  routes : Array[@http.RouteSpec],
  pages : Array[@view.PageModule],
  server_actions : Array[@view.ServerAction],
  scaffolds : Array[@generator.ScaffoldPlan],
) -> MbtOnRailsApp {
  {
    name,
    auth,
    models,
    migrations,
    middlewares,
    fixtures,
    seeds,
    cable_channels,
    job_queues,
    mailers,
    caches,
    controllers,
    routes,
    pages,
    server_actions,
    scaffolds,
  }
}

///|
/// Renders the client router manifest for this app.
pub fn MbtOnRailsApp::router_manifest(self : MbtOnRailsApp) -> String {
  @view.render_router_manifest(self.pages)
}

///|
/// Renders the route tree for this app's pages.
pub fn MbtOnRailsApp::route_tree(self : MbtOnRailsApp) -> String {
  @view.render_route_tree(self.pages)
}

///|
/// Renders the schema SQL produced by this app's migrations.
pub fn MbtOnRailsApp::schema_statements(self : MbtOnRailsApp) -> Array[String] {
  @migration.schema_sql(self.migrations)
}

///|
/// Renders the model-derived schema dump for this app.
pub fn MbtOnRailsApp::schema_dump(self : MbtOnRailsApp) -> String {
  @orm.schema_dump(self.models)
}

///|
/// Renders the routing table in a CLI-friendly format.
pub fn MbtOnRailsApp::routes_table(self : MbtOnRailsApp) -> String {
  let lines : Array[String] = []
  for route in self.routes {
    lines.push(
      route.verb.to_string() +
      " " +
      route.pattern.raw +
      " -> " +
      route.controller +
      "#" +
      route.action,
    )
  }
  lines.join("\n")
}

///|
/// Renders controller summaries for the app.
pub fn MbtOnRailsApp::controller_table(self : MbtOnRailsApp) -> String {
  let blocks : Array[String] = []
  for controller in self.controllers {
    blocks.push(@controller.controller_summary(controller))
  }
  blocks.join("\n\n")
}

///|
/// Renders scaffold summaries for the app.
pub fn MbtOnRailsApp::scaffold_table(self : MbtOnRailsApp) -> String {
  let blocks : Array[String] = []
  for scaffold in self.scaffolds {
    blocks.push(@generator.scaffold_summary(scaffold))
  }
  blocks.join("\n\n")
}

///|
/// Returns an example HTML render for a `GET` request path.
pub fn MbtOnRailsApp::example_html(
  self : MbtOnRailsApp,
  path : String,
) -> String? {
  let response = handle_request(
    self,
    @http.request(@http.http_get(), path, [], [], None, ""),
  )
  match response.body {
    @http.Html(body) => Some(body)
    _ => None
  }
}
