///|
/// Starts an app descriptor with sensible defaults and empty collections.
pub fn app_named(name : String) -> MbtOnRailsApp {
  {
    name,
    auth: @auth.default_auth_config(),
    models: [],
    migrations: [],
    middlewares: [],
    fixtures: [],
    seeds: [],
    cable_channels: [],
    job_queues: [],
    mailers: [],
    caches: [],
    controllers: [],
    routes: [],
    pages: [],
    server_actions: [],
    scaffolds: [],
  }
}

fn[T] push_item(items : Array[T], item : T) -> Array[T] {
  let next = @support.clone_array(items)
  next.push(item)
  next
}

fn[T] append_items(items : Array[T], more : Array[T]) -> Array[T] {
  let next = @support.clone_array(items)
  for item in more {
    next.push(item)
  }
  next
}

pub fn MbtOnRailsApp::with_auth(
  self : MbtOnRailsApp,
  auth : @auth.AuthConfig,
) -> MbtOnRailsApp {
  { ..self, auth }
}

pub fn MbtOnRailsApp::with_model(
  self : MbtOnRailsApp,
  model : @orm.ModelSchema,
) -> MbtOnRailsApp {
  { ..self, models: push_item(self.models, model) }
}

pub fn MbtOnRailsApp::with_models(
  self : MbtOnRailsApp,
  models : Array[@orm.ModelSchema],
) -> MbtOnRailsApp {
  { ..self, models: append_items(self.models, models) }
}

pub fn MbtOnRailsApp::with_migration(
  self : MbtOnRailsApp,
  migration : @migration.Migration,
) -> MbtOnRailsApp {
  { ..self, migrations: push_item(self.migrations, migration) }
}

pub fn MbtOnRailsApp::with_migrations(
  self : MbtOnRailsApp,
  migrations : Array[@migration.Migration],
) -> MbtOnRailsApp {
  { ..self, migrations: append_items(self.migrations, migrations) }
}

pub fn MbtOnRailsApp::with_middleware(
  self : MbtOnRailsApp,
  middleware : @middleware.Middleware,
) -> MbtOnRailsApp {
  { ..self, middlewares: push_item(self.middlewares, middleware) }
}

pub fn MbtOnRailsApp::with_middlewares(
  self : MbtOnRailsApp,
  middlewares : Array[@middleware.Middleware],
) -> MbtOnRailsApp {
  { ..self, middlewares: append_items(self.middlewares, middlewares) }
}

pub fn MbtOnRailsApp::with_fixture(
  self : MbtOnRailsApp,
  fixture : @fixture.FixtureSet,
) -> MbtOnRailsApp {
  { ..self, fixtures: push_item(self.fixtures, fixture) }
}

pub fn MbtOnRailsApp::with_fixtures(
  self : MbtOnRailsApp,
  fixtures : Array[@fixture.FixtureSet],
) -> MbtOnRailsApp {
  { ..self, fixtures: append_items(self.fixtures, fixtures) }
}

pub fn MbtOnRailsApp::with_seed(
  self : MbtOnRailsApp,
  seed : @fixture.SeedPlan,
) -> MbtOnRailsApp {
  { ..self, seeds: push_item(self.seeds, seed) }
}

pub fn MbtOnRailsApp::with_seeds(
  self : MbtOnRailsApp,
  seeds : Array[@fixture.SeedPlan],
) -> MbtOnRailsApp {
  { ..self, seeds: append_items(self.seeds, seeds) }
}

pub fn MbtOnRailsApp::with_cable_channel(
  self : MbtOnRailsApp,
  channel : @cable.CableChannel,
) -> MbtOnRailsApp {
  { ..self, cable_channels: push_item(self.cable_channels, channel) }
}

pub fn MbtOnRailsApp::with_cable_channels(
  self : MbtOnRailsApp,
  channels : Array[@cable.CableChannel],
) -> MbtOnRailsApp {
  { ..self, cable_channels: append_items(self.cable_channels, channels) }
}

pub fn MbtOnRailsApp::with_job_queue(
  self : MbtOnRailsApp,
  queue : @job.JobQueue,
) -> MbtOnRailsApp {
  { ..self, job_queues: push_item(self.job_queues, queue) }
}

pub fn MbtOnRailsApp::with_job_queues(
  self : MbtOnRailsApp,
  queues : Array[@job.JobQueue],
) -> MbtOnRailsApp {
  { ..self, job_queues: append_items(self.job_queues, queues) }
}

pub fn MbtOnRailsApp::with_mailer(
  self : MbtOnRailsApp,
  mailer : @mailer.MailerDefinition,
) -> MbtOnRailsApp {
  { ..self, mailers: push_item(self.mailers, mailer) }
}

pub fn MbtOnRailsApp::with_mailers(
  self : MbtOnRailsApp,
  mailers : Array[@mailer.MailerDefinition],
) -> MbtOnRailsApp {
  { ..self, mailers: append_items(self.mailers, mailers) }
}

pub fn MbtOnRailsApp::with_cache(
  self : MbtOnRailsApp,
  cache : @cache.CacheStore,
) -> MbtOnRailsApp {
  { ..self, caches: push_item(self.caches, cache) }
}

pub fn MbtOnRailsApp::with_caches(
  self : MbtOnRailsApp,
  caches : Array[@cache.CacheStore],
) -> MbtOnRailsApp {
  { ..self, caches: append_items(self.caches, caches) }
}

pub fn MbtOnRailsApp::with_controller(
  self : MbtOnRailsApp,
  controller : @controller.ControllerDefinition,
) -> MbtOnRailsApp {
  { ..self, controllers: push_item(self.controllers, controller) }
}

pub fn MbtOnRailsApp::with_controllers(
  self : MbtOnRailsApp,
  controllers : Array[@controller.ControllerDefinition],
) -> MbtOnRailsApp {
  { ..self, controllers: append_items(self.controllers, controllers) }
}

pub fn MbtOnRailsApp::with_route(
  self : MbtOnRailsApp,
  route : @http.RouteSpec,
) -> MbtOnRailsApp {
  { ..self, routes: push_item(self.routes, route) }
}

pub fn MbtOnRailsApp::with_routes(
  self : MbtOnRailsApp,
  routes : Array[@http.RouteSpec],
) -> MbtOnRailsApp {
  { ..self, routes: append_items(self.routes, routes) }
}

pub fn MbtOnRailsApp::with_page(
  self : MbtOnRailsApp,
  page : @view.PageModule,
) -> MbtOnRailsApp {
  { ..self, pages: push_item(self.pages, page) }
}

pub fn MbtOnRailsApp::with_pages(
  self : MbtOnRailsApp,
  pages : Array[@view.PageModule],
) -> MbtOnRailsApp {
  { ..self, pages: append_items(self.pages, pages) }
}

pub fn MbtOnRailsApp::with_server_action(
  self : MbtOnRailsApp,
  action : @view.ServerAction,
) -> MbtOnRailsApp {
  { ..self, server_actions: push_item(self.server_actions, action) }
}

pub fn MbtOnRailsApp::with_server_actions(
  self : MbtOnRailsApp,
  actions : Array[@view.ServerAction],
) -> MbtOnRailsApp {
  { ..self, server_actions: append_items(self.server_actions, actions) }
}

pub fn MbtOnRailsApp::with_scaffold(
  self : MbtOnRailsApp,
  scaffold : @generator.ScaffoldPlan,
) -> MbtOnRailsApp {
  { ..self, scaffolds: push_item(self.scaffolds, scaffold) }
}

pub fn MbtOnRailsApp::with_scaffolds(
  self : MbtOnRailsApp,
  scaffolds : Array[@generator.ScaffoldPlan],
) -> MbtOnRailsApp {
  { ..self, scaffolds: append_items(self.scaffolds, scaffolds) }
}
