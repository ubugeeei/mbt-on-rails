///|
fn main {
  let config = @mbor.default_production_config()
  let checks = [
    @mbor.health_check("database", true, "primary reachable"),
    @mbor.health_check("redis", true, "queue online"),
    @mbor.health_check("mail", false, "smtp timeout"),
  ]
  let limit = @mbor.rate_limit_rule("api-write", "/api", 60, 60)
  let event = @mbor.log_event("info", "request completed", Some("req_123"), [
    ("path", "/api/posts"),
    ("status", "200"),
  ])

  println("Production Stack Example")
  println("========================")
  println("")
  println("Config")
  println(@mbor.config_summary(config))
  println("")
  println("Health")
  println(@mbor.render_health_json(checks))
  println("")
  println("Rate Limit")
  println(@mbor.rate_limit_summary(limit))
  println(
    "rate limited at 61 hits = " + @mbor.rate_limited(limit, 61).to_string(),
  )
  println("")
  println("JSON Log")
  println(@mbor.json_log(event))
}
