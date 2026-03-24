///|
/// Lists the deployment environments supported by the framework.
pub enum Environment {
  Development
  Test
  Staging
  Production
} derive(Eq, Show)

///|
/// Captures deployment-time configuration that affects runtime behavior.
pub struct DeploymentConfig {
  environment : Environment
  host : String
  port : Int
  force_ssl : Bool
  trust_proxy : Bool
  asset_host : String?
  health_path : String
  ready_path : String
}

///|
/// Represents one health or readiness probe result.
pub struct HealthCheck {
  name : String
  ok : Bool
  detail : String
}

///|
/// Declares one rate limit rule.
pub struct RateLimitRule {
  name : String
  path_prefix : String
  limit : Int
  window_seconds : Int
}

///|
/// Represents one structured log event.
pub struct LogEvent {
  level : String
  message : String
  request_id : String?
  metadata : Array[(String, String)]
}

///|
/// Builds a deployment config.
pub fn deployment_config(
  environment : Environment,
  host : String,
  port : Int,
  force_ssl : Bool,
  trust_proxy : Bool,
  asset_host : String?,
  health_path : String,
  ready_path : String,
) -> DeploymentConfig {
  {
    environment,
    host,
    port,
    force_ssl,
    trust_proxy,
    asset_host,
    health_path,
    ready_path,
  }
}

///|
/// Returns a development-leaning default config.
pub fn default_development_config() -> DeploymentConfig {
  deployment_config(
    Development,
    "127.0.0.1",
    3000,
    false,
    false,
    None,
    "/health",
    "/ready",
  )
}

///|
/// Returns a test-leaning default config.
pub fn default_test_config() -> DeploymentConfig {
  deployment_config(
    Test,
    "127.0.0.1",
    3001,
    false,
    false,
    None,
    "/health",
    "/ready",
  )
}

///|
/// Returns a staging-leaning default config.
pub fn default_staging_config() -> DeploymentConfig {
  deployment_config(
    Staging,
    "0.0.0.0",
    3000,
    true,
    true,
    None,
    "/health",
    "/ready",
  )
}

///|
/// Returns a production-leaning default config.
pub fn default_production_config() -> DeploymentConfig {
  deployment_config(
    Production,
    "0.0.0.0",
    3000,
    true,
    true,
    None,
    "/health",
    "/ready",
  )
}

///|
/// Builds one probe result.
pub fn health_check(name : String, ok : Bool, detail : String) -> HealthCheck {
  { name, ok, detail }
}

///|
/// Builds one rate limit rule.
pub fn rate_limit_rule(
  name : String,
  path_prefix : String,
  limit : Int,
  window_seconds : Int,
) -> RateLimitRule {
  { name, path_prefix, limit, window_seconds }
}

///|
/// Builds one structured log event.
pub fn log_event(
  level : String,
  message : String,
  request_id : String?,
  metadata : Array[(String, String)],
) -> LogEvent {
  { level, message, request_id, metadata }
}
