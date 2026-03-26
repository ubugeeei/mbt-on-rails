///|
/// Runtime and delivery helpers that complement the main facade.

///|
pub using @cable {
  type CableBroadcast,
  type CableChannel,
  broadcast_summary,
  broadcast_turbo,
  cable_broadcast,
  cable_channel,
  cable_summary,
}

///|
pub using @middleware {
  type Middleware,
  apply_request_middleware,
  apply_response_middleware,
  halt_with_text,
  middleware,
  middleware_summary,
  with_request_header,
  with_response_header,
}

///|
pub using @fixture {
  type FixtureRow,
  type FixtureSet,
  type SeedPlan,
  apply_seed,
  fixture_row,
  fixture_set,
  fixture_summary,
  load_fixture_set,
  load_fixtures,
  seed_plan,
  seed_summary,
}

///|
pub using @turbo {
  type TurboStream,
  type TurboStreamAction,
  append_stream,
  ok_turbo_stream,
  prepend_stream,
  remove_stream,
  render_turbo_stream,
  replace_stream,
  turbo_stream,
  update_stream,
}

///|
/// Extra Rails-style surfaces that keep the main facade compact.
pub using @controller {
  deliver_mail_step,
  enqueue_job_step,
  permit_params_step,
  touch_cache_step,
}

///|
pub using @params {
  type Parameters,
  type PermittedParams,
  merge_params,
  param_value,
  params,
  permit,
  permit_scope,
  permitted_attributes,
  permitted_summary,
  permitted_value,
  require_scope,
}

///|
pub using @job {
  type DrainedJobs,
  type EnqueuedJob,
  type JobDefinition,
  type JobQueue,
  drain_ready,
  enqueue_at,
  enqueue_now,
  enqueued_job,
  job,
  job_queue,
  job_ready,
  job_summary,
  retry_job,
}

///|
pub using @mailer {
  type MailDelivery,
  type MailTemplate,
  type MailerDefinition,
  compose_mail,
  delivery_job,
  enqueue_delivery,
  mail_template,
  mailer,
  mailer_summary,
  with_bcc,
  with_cc,
}

///|
pub using @cache {
  type CacheEntry,
  type CacheFetchResult,
  type CacheStore,
  cache_delete,
  cache_delete_tag,
  cache_fetch,
  cache_key,
  cache_read,
  cache_store,
  cache_summary,
  cache_write,
}

///|
/// Production-oriented helpers for deployment, health, and logging.
pub using @production {
  type DeploymentConfig,
  type Environment,
  type HealthCheck,
  type LogEvent,
  type RateLimitRule,
  config_summary,
  default_development_config,
  default_production_config,
  default_staging_config,
  default_test_config,
  deployment_config,
  health_response,
  health_check,
  json_api_document,
  json_api_error,
  json_api_ok,
  json_log,
  log_event,
  metrics_response,
  rate_limit_rule,
  rate_limit_summary,
  rate_limited,
  readiness_response,
  render_health_json,
}

///|
/// Deployment topology helpers for web, worker, cable, and release processes.
pub using @process {
  type ProcessDefinition,
  type ProcessRole,
  type ReleaseTask,
  cable_process,
  env_keys_summary,
  process_definition,
  process_summary,
  release_summary,
  release_process,
  release_task,
  scheduler_process,
  web_process,
  worker_process,
}

///|
/// Observability and secrets helpers for production deployments.
pub using @metrics {
  type MetricKind,
  type MetricSample,
  type MetricsRegistry,
  counter,
  gauge,
  increment_metric,
  metric_value,
  metrics_registry,
  metrics_summary,
  render_prometheus,
  set_metric,
  with_metric,
}

///|
pub using @secrets {
  type SecretVar,
  type SecretsConfig,
  dotenv_preview,
  masked_secret_summary,
  missing_secrets,
  secret_value,
  secret_var,
  secrets_config,
  secrets_valid,
}
