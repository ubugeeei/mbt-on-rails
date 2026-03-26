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
#label_migration(environment, allow_positional=true)
#label_migration(host, allow_positional=true)
#label_migration(port, allow_positional=true)
#label_migration(force_ssl, allow_positional=true)
#label_migration(trust_proxy, allow_positional=true)
#label_migration(asset_host, allow_positional=true)
#label_migration(health_path, allow_positional=true)
#label_migration(ready_path, allow_positional=true)
pub fn deployment_config(
  environment~ : Environment,
  host~ : String,
  port~ : Int,
  force_ssl~ : Bool,
  trust_proxy~ : Bool,
  asset_host~ : String?,
  health_path~ : String,
  ready_path~ : String,
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
    environment=Development,
    host="127.0.0.1",
    port=3000,
    force_ssl=false,
    trust_proxy=false,
    asset_host=None,
    health_path="/health",
    ready_path="/ready",
  )
}

///|
/// Returns a test-leaning default config.
pub fn default_test_config() -> DeploymentConfig {
  deployment_config(
    environment=Test,
    host="127.0.0.1",
    port=3001,
    force_ssl=false,
    trust_proxy=false,
    asset_host=None,
    health_path="/health",
    ready_path="/ready",
  )
}

///|
/// Returns a staging-leaning default config.
pub fn default_staging_config() -> DeploymentConfig {
  deployment_config(
    environment=Staging,
    host="0.0.0.0",
    port=3000,
    force_ssl=true,
    trust_proxy=true,
    asset_host=None,
    health_path="/health",
    ready_path="/ready",
  )
}

///|
/// Returns a production-leaning default config.
pub fn default_production_config() -> DeploymentConfig {
  deployment_config(
    environment=Production,
    host="0.0.0.0",
    port=3000,
    force_ssl=true,
    trust_proxy=true,
    asset_host=None,
    health_path="/health",
    ready_path="/ready",
  )
}

///|
/// Builds one probe result.
#label_migration(name, allow_positional=true)
#label_migration(ok, allow_positional=true)
#label_migration(detail, allow_positional=true)
pub fn health_check(
  name~ : String,
  ok~ : Bool,
  detail~ : String,
) -> HealthCheck {
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
