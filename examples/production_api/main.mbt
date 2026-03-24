///|
/// Builds a small versioned API route table.
fn api_routes() -> Array[@mbor.RouteSpec] {
  [
    @mbor.route(
      "health",
      @mbor.http_get(),
      "/health",
      "HealthController",
      "show",
      None,
    ),
    @mbor.route(
      "ready",
      @mbor.http_get(),
      "/ready",
      "ReadyController",
      "show",
      None,
    ),
    @mbor.route(
      "metrics",
      @mbor.http_get(),
      "/metrics",
      "MetricsController",
      "show",
      None,
    ),
    @mbor.route(
      "post_show",
      @mbor.http_get(),
      "/api/v1/posts/[id]",
      "Api::PostsController",
      "show",
      None,
    ),
  ]
}

///|
/// Dispatches one request against the API example.
fn dispatch(
  routes : Array[@mbor.RouteSpec],
  registry : @mbor.MetricsRegistry,
  request : @mbor.Request,
) -> @mbor.Response {
  match @mbor.recognize(routes, request) {
    Some(matched) =>
      if matched.route.name == "health" {
        return @mbor.health_response([@mbor.health_check("app", true, "ok")])
      } else if matched.route.name == "ready" {
        return @mbor.readiness_response([
          @mbor.health_check("db", true, "connected"),
        ])
      } else if matched.route.name == "metrics" {
        return @mbor.metrics_response(@mbor.render_prometheus(registry))
      } else {
        match @mbor.find_entry(matched.params, "id") {
          Some(id) =>
            @mbor.json_api_ok("posts", id, [
              ("title", "MoonBit on Rails API"),
              ("published", "true"),
            ])
          None => @mbor.json_api_error(404, "not_found", "post not found")
        }
      }
    None => @mbor.json_api_error(404, "not_found", "route not found")
  }
}

///|
fn main {
  let routes = api_routes()
  let registry = @mbor.with_metric(
    @mbor.set_metric(
      @mbor.increment_metric(
        @mbor.metrics_registry(),
        "http_requests_total",
        [("controller", "Api::PostsController")],
        12,
      ),
      "db_pool_available",
      [],
      4,
    ),
    @mbor.counter("job_executions_total", [("queue", "default")], 8),
  )
  let secrets = @mbor.secrets_config([
    @mbor.secret_var(
      "DATABASE_URL",
      Some("postgres://app:secret@db/prod"),
      true,
      true,
    ),
    @mbor.secret_var("REDIS_URL", Some("redis://cache:6379/0"), true, false),
    @mbor.secret_var("SMTP_PASSWORD", None, true, true),
  ])

  println("Production API Example")
  println("======================")
  println("")
  println("Routes")
  for route in routes {
    println(
      route.verb.to_string() +
      " " +
      route.pattern.raw +
      " -> " +
      route.controller +
      "#" +
      route.action,
    )
  }
  println("")
  println("Secrets")
  println(@mbor.masked_secret_summary(secrets))
  println("missing = " + @mbor.missing_secrets(secrets).join(", "))
  println("")

  let health = dispatch(
    routes,
    registry,
    @mbor.request(@mbor.http_get(), "/health", [], [], None, ""),
  )
  let ready = dispatch(
    routes,
    registry,
    @mbor.request(@mbor.http_get(), "/ready", [], [], None, ""),
  )
  let metrics = dispatch(
    routes,
    registry,
    @mbor.request(@mbor.http_get(), "/metrics", [], [], None, ""),
  )
  let post = dispatch(
    routes,
    registry,
    @mbor.request(@mbor.http_get(), "/api/v1/posts/42", [], [], None, ""),
  )

  println("Health")
  println(@mbor.render_response_body(health.body))
  println("")
  println("Ready")
  println(@mbor.render_response_body(ready.body))
  println("")
  println("Metrics")
  println(@mbor.render_response_body(metrics.body))
  println("")
  println("Post")
  println(@mbor.render_response_body(post.body))
}
