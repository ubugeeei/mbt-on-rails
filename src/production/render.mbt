///|
/// Renders a deployment config in a CLI-friendly format.
pub fn config_summary(config : DeploymentConfig) -> String {
  let asset_host = match config.asset_host {
    Some(host) => host
    None => "-"
  }
  render_environment(config.environment) +
  " host=" +
  config.host +
  ":" +
  config.port.to_string() +
  " force_ssl=" +
  config.force_ssl.to_string() +
  " trust_proxy=" +
  config.trust_proxy.to_string() +
  " asset_host=" +
  asset_host
}

///|
/// Renders health and readiness checks into JSON.
pub fn render_health_json(checks : Array[HealthCheck]) -> String {
  let entries : Array[String] = []
  let mut healthy = true
  for check in checks {
    if not(check.ok) {
      healthy = false
    }
    entries.push(
      "{" +
      "\"name\": " +
      @support.json_string(check.name) +
      ", \"ok\": " +
      (if check.ok { "true" } else { "false" }) +
      ", \"detail\": " +
      @support.json_string(check.detail) +
      "}",
    )
  }
  "{" +
  "\"status\": " +
  @support.json_string(if healthy { "ok" } else { "degraded" }) +
  ", \"checks\": [" +
  entries.join(", ") +
  "]" +
  "}"
}

///|
/// Renders a rate limit rule in a CLI-friendly format.
pub fn rate_limit_summary(rule : RateLimitRule) -> String {
  rule.name +
  " path=" +
  rule.path_prefix +
  " limit=" +
  rule.limit.to_string() +
  "/" +
  rule.window_seconds.to_string() +
  "s"
}

///|
/// Returns whether a hit count breaches the configured rate limit.
pub fn rate_limited(rule : RateLimitRule, hits_in_window : Int) -> Bool {
  hits_in_window > rule.limit
}

///|
/// Renders one structured log event as a JSON line.
pub fn json_log(event : LogEvent) -> String {
  let request_id = match event.request_id {
    Some(value) => @support.json_string(value)
    None => "null"
  }
  "{" +
  "\"level\": " +
  @support.json_string(event.level) +
  ", \"message\": " +
  @support.json_string(event.message) +
  ", \"request_id\": " +
  request_id +
  ", \"metadata\": " +
  @support.entries_to_json(event.metadata) +
  "}"
}

///|
/// Renders one deployment environment into a lowercase token.
fn render_environment(environment : Environment) -> String {
  match environment {
    Development => "development"
    Test => "test"
    Staging => "staging"
    Production => "production"
  }
}
