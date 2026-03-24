///|
/// Builds the metrics registry used by the production API example tests.
fn example_registry() -> @mbor.MetricsRegistry {
  @mbor.with_metric(
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
}

///|
test "production api dispatches health metrics resources and not found paths" {
  let routes = api_routes()
  let registry = example_registry()
  assert_eq(routes.length(), 4)

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
  let missing = dispatch(
    routes,
    registry,
    @mbor.request(@mbor.http_get(), "/missing", [], [], None, ""),
  )

  assert_eq(health.status, 200)
  assert_eq(ready.status, 200)
  assert_true(
    @mbor.render_response_body(metrics.body).contains("http_requests_total"),
  )
  assert_true(@mbor.render_response_body(post.body).contains("\"id\": \"42\""))
  assert_eq(missing.status, 404)
}

///|
test "production api main smoke stays runnable" {
  run_example()
  assert_true(true)
}
