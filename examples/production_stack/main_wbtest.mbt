///|
test "production stack example summaries stay stable" {
  let config = @mbor.default_production_config()
  let checks = [
    @mbor.health_check(name="database", ok=true, detail="primary reachable"),
    @mbor.health_check(name="redis", ok=true, detail="queue online"),
    @mbor.health_check(name="mail", ok=false, detail="smtp timeout"),
  ]
  let limit = @mbor.rate_limit_rule("api-write", "/api", 60, 60)
  let event = @mbor.log_event("info", "request completed", Some("req_123"), [
    ("path", "/api/posts"),
    ("status", "200"),
  ])

  assert_true(@mbor.config_summary(config).contains("production"))
  assert_true(
    @mbor.render_health_json(checks).contains("\"status\": \"degraded\""),
  )
  assert_true(@mbor.rate_limited(limit, 61))
  assert_true(@mbor.json_log(event).contains("\"request_id\": \"req_123\""))
}

///|
test "production stack main smoke stays runnable" {
  run_example()
  assert_true(true)
}
