///|
/// Builds a small versioned API route table.
fn api_routes() -> Array[@mbor.RouteSpec] {
  [
    @mbor.route(
      name="health",
      verb=@mbor.http_get(),
      path="/health",
      controller="HealthController",
      action="show",
      page_name=None,
    ),
    @mbor.route(
      name="ready",
      verb=@mbor.http_get(),
      path="/ready",
      controller="ReadyController",
      action="show",
      page_name=None,
    ),
    @mbor.route(
      name="metrics",
      verb=@mbor.http_get(),
      path="/metrics",
      controller="MetricsController",
      action="show",
      page_name=None,
    ),
    @mbor.route(
      name="post_show",
      verb=@mbor.http_get(),
      path="/api/v1/posts/[id]",
      controller="Api::PostsController",
      action="show",
      page_name=None,
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
        return @mbor.health_response([
          @mbor.health_check(name="app", ok=true, detail="ok"),
        ])
      } else if matched.route.name == "ready" {
        return @mbor.readiness_response([
          @mbor.health_check(name="db", ok=true, detail="connected"),
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
/// Runs the production API example output.
fn run_example() -> Unit {
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
      name="DATABASE_URL",
      value=Some("postgres://app:secret@db/prod"),
      required=true,
      sensitive=true,
    ),
    @mbor.secret_var(
      name="REDIS_URL",
      value=Some("redis://cache:6379/0"),
      required=true,
      sensitive=false,
    ),
    @mbor.secret_var(
      name="SMTP_PASSWORD",
      value=None,
      required=true,
      sensitive=true,
    ),
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
    @mbor.request(
      verb=@mbor.http_get(),
      path="/health",
      query=[],
      form=[],
      session_id=None,
      body="",
    ),
  )
  let ready = dispatch(
    routes,
    registry,
    @mbor.request(
      verb=@mbor.http_get(),
      path="/ready",
      query=[],
      form=[],
      session_id=None,
      body="",
    ),
  )
  let metrics = dispatch(
    routes,
    registry,
    @mbor.request(
      verb=@mbor.http_get(),
      path="/metrics",
      query=[],
      form=[],
      session_id=None,
      body="",
    ),
  )
  let post = dispatch(
    routes,
    registry,
    @mbor.request(
      verb=@mbor.http_get(),
      path="/api/v1/posts/42",
      query=[],
      form=[],
      session_id=None,
      body="",
    ),
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

///|
fn main {
  run_example()
}
