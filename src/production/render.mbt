///|
/// Renders a deployment config in a CLI-friendly format.
pub fn config_summary(config : DeploymentConfig) -> String {
  let asset_host = match config.asset_host {
    Some(host) => host
    None => "-"
  }
  let issues = validate_deployment_config(config)
  let validation = if issues.is_empty() {
    ""
  } else {
    " invalid=" + issues.join("; ")
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
  asset_host +
  validation
}

///|
/// Returns whether a deployment config is safe enough to boot.
pub fn deployment_config_valid(config : DeploymentConfig) -> Bool {
  validate_deployment_config(config).is_empty()
}

///|
/// Reports invalid deployment config inputs without mutating them.
pub fn validate_deployment_config(config : DeploymentConfig) -> Array[String] {
  let issues : Array[String] = []
  if !valid_host(config.host) {
    issues.push("host must be a hostname or IPv4 literal")
  }
  match config.asset_host {
    Some(host) =>
      if !valid_asset_host(host) {
        issues.push("asset_host must be an http(s) URL or host")
      }
    None => ()
  }
  if config.port < 1 || config.port > 65535 {
    issues.push("port must be between 1 and 65535")
  }
  if !valid_probe_path(config.health_path) {
    issues.push("health_path must be an absolute path")
  }
  if !valid_probe_path(config.ready_path) {
    issues.push("ready_path must be an absolute path")
  }
  issues
}

///|
/// Renders health and readiness checks into JSON.
pub fn render_health_json(checks : Array[HealthCheck]) -> String {
  let entries : Array[String] = []
  let mut healthy = !checks.is_empty()
  for check in checks {
    if !check.ok {
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
  let issues = validate_rate_limit_rule(rule)
  let validation = if issues.is_empty() {
    ""
  } else {
    " invalid=" + issues.join("; ")
  }
  rule.name +
  " path=" +
  rule.path_prefix +
  " limit=" +
  rule.limit.to_string() +
  "/" +
  rule.window_seconds.to_string() +
  "s" +
  validation
}

///|
/// Returns whether a rate limit rule has valid runtime bounds.
pub fn rate_limit_rule_valid(rule : RateLimitRule) -> Bool {
  validate_rate_limit_rule(rule).is_empty()
}

///|
/// Reports invalid rate limit rule inputs without mutating them.
pub fn validate_rate_limit_rule(rule : RateLimitRule) -> Array[String] {
  let issues : Array[String] = []
  if rule.name.trim().to_owned().length() == 0 || has_control(rule.name) {
    issues.push("name must be present")
  }
  if !valid_probe_path(rule.path_prefix) {
    issues.push("path_prefix must be an absolute path")
  }
  if rule.limit < 1 {
    issues.push("limit must be greater than 0")
  }
  if rule.window_seconds < 1 {
    issues.push("window_seconds must be greater than 0")
  }
  issues
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

///|
fn valid_asset_host(source : String) -> Bool {
  let value = source.trim().to_owned()
  if value.length() == 0 || has_control(value) {
    return false
  }
  if value.has_prefix("http://") {
    valid_host(url_host(value, scheme_length=7))
  } else if value.has_prefix("https://") {
    valid_host(url_host(value, scheme_length=8))
  } else if value.contains("://") {
    false
  } else {
    valid_host(value)
  }
}

///|
fn url_host(source : String, scheme_length~ : Int) -> String {
  let mut end = scheme_length
  while end < source.length() {
    let ch = source[end]
    if ch == '/' || ch == ':' || ch == '?' || ch == '#' {
      break
    }
    end += 1
  }
  String::unsafe_substring(source, start=scheme_length, end~)
}

///|
fn valid_host(source : String) -> Bool {
  let value = source.trim().to_owned()
  if value.length() == 0 ||
    value.contains("://") ||
    value.contains("/") ||
    value.contains("\\") ||
    has_control(value) {
    return false
  }
  let mut label_length = 0
  let mut last_was_dot = false
  let mut last_was_dash = false
  for ch in value {
    if valid_host_char(ch) {
      if label_length == 0 && ch == '-' {
        return false
      }
      label_length += 1
      last_was_dot = false
      last_was_dash = ch == '-'
    } else if ch == '.' {
      if last_was_dot || label_length == 0 || last_was_dash {
        return false
      }
      label_length = 0
      last_was_dot = true
      last_was_dash = false
    } else {
      return false
    }
  }
  label_length > 0 && !last_was_dot && !last_was_dash
}

///|
fn valid_host_char(ch : Char) -> Bool {
  (ch >= 'A' && ch <= 'Z') ||
  (ch >= 'a' && ch <= 'z') ||
  (ch >= '0' && ch <= '9') ||
  ch == '-'
}

///|
fn valid_probe_path(source : String) -> Bool {
  let value = source.trim().to_owned()
  value.length() > 0 &&
  value == source &&
  value.has_prefix("/") &&
  !value.has_prefix("//") &&
  !value.contains("?") &&
  !value.contains("#") &&
  !value.contains("\\") &&
  !has_control(value) &&
  !has_space(value)
}

///|
fn has_control(source : String) -> Bool {
  for ch in source {
    match ch {
      '\n' | '\r' | '\t' => return true
      _ => ()
    }
  }
  false
}

///|
fn has_space(source : String) -> Bool {
  for ch in source {
    if ch == ' ' {
      return true
    }
  }
  false
}
