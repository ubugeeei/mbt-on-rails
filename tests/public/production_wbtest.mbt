///|
test "metrics secrets and production http helpers are production friendly" {
  let registry = with_metric(
    set_metric(
      increment_metric(
        metrics_registry(),
        "http_requests_total",
        [("controller", "PostsController")],
        5,
      ),
      "db_pool_available",
      [],
      4,
    ),
    counter("job_executions_total", [("queue", "default")], 2),
  )
  assert_eq(
    metric_value(registry, "http_requests_total", [
      ("controller", "PostsController"),
    ]),
    5,
  )
  assert_true(
    render_prometheus(registry).contains("# TYPE http_requests_total counter"),
  )

  let secrets = secrets_config([
    secret_var(
      name="DATABASE_URL",
      value=Some("postgres://app:secret@db/prod"),
      required=true,
      sensitive=true,
    ),
    secret_var(name="SMTP_PASSWORD", value=None, required=true, sensitive=true),
  ])
  assert_false(secrets_valid(secrets))
  assert_true(masked_secret_summary(secrets).contains("po****od"))
  assert_eq(missing_secrets(secrets)[0], "SMTP_PASSWORD")

  let healthy = health_response([health_check(name="app", ok=true, detail="ok")])
  let empty = health_response([])
  let metrics = metrics_response(render_prometheus(registry))
  let api_ok = json_api_ok("posts", "42", [("title", "MoonBit")])
  let api_error = json_api_error(404, "not_found", "missing")

  assert_eq(healthy.status, 200)
  assert_eq(empty.status, 503)
  assert_true(
    render_response_body(empty.body).contains("\"status\": \"degraded\""),
  )
  assert_eq(metrics.headers[0].1, "text/plain; version=0.0.4; charset=utf-8")
  assert_true(render_response_body(api_ok.body).contains("\"type\": \"posts\""))
  assert_true(
    render_response_body(api_error.body).contains("\"code\": \"not_found\""),
  )
}

///|
test "secrets validation reports invalid env names and sanitizes summaries" {
  let secrets = secrets_config([
    secret_var(
      name="BAD-NAME",
      value=Some("ok"),
      required=true,
      sensitive=false,
    ),
    secret_var(
      name="PUBLIC_BANNER",
      value=Some("example.com\nDATABASE_URL=oops\r"),
      required=false,
      sensitive=false,
    ),
  ])

  assert_false(secrets_valid(secrets))
  assert_eq(invalid_secret_names(secrets)[0], "BAD-NAME")
  let summary = masked_secret_summary(secrets)
  assert_true(summary.contains("PUBLIC_BANNER=example.com DATABASE_URL=oops"))
  assert_false(summary.contains("\nDATABASE_URL=oops"))
  assert_false(summary.contains("\r"))
}

///|
test "production runtime validation flags unsafe config and rate limits" {
  let base = default_production_config()
  let config = deployment_config(
    environment=base.environment,
    host="https://example.com",
    port=0,
    force_ssl=true,
    trust_proxy=true,
    asset_host=Some("javascript:alert(1)"),
    health_path="health",
    ready_path="//ready",
  )

  let config_issues = validate_deployment_config(config)
  assert_false(deployment_config_valid(config))
  assert_true(config_issues.contains("host must be a hostname or IPv4 literal"))
  assert_true(config_issues.contains("port must be between 1 and 65535"))
  assert_true(config_issues.contains("health_path must be an absolute path"))
  assert_true(config_issues.contains("ready_path must be an absolute path"))
  assert_true(config_summary(config).contains("invalid="))

  let rule = rate_limit_rule("", "api", 0, -1)
  let rule_issues = validate_rate_limit_rule(rule)
  assert_false(rate_limit_rule_valid(rule))
  assert_true(rule_issues.contains("name must be present"))
  assert_true(rule_issues.contains("path_prefix must be an absolute path"))
  assert_true(rule_issues.contains("limit must be greater than 0"))
  assert_true(rule_issues.contains("window_seconds must be greater than 0"))
  assert_true(rate_limit_summary(rule).contains("invalid="))
}

///|
test "prometheus rendering emits one type line per metric name" {
  let registry = with_metric(
    with_metric(
      metrics_registry(),
      counter("http_requests_total", [("controller", "PostsController")], 5),
    ),
    counter("http_requests_total", [("controller", "CommentsController")], 3),
  )

  assert_eq(
    render_prometheus(registry),
    "# TYPE http_requests_total counter\nhttp_requests_total{controller=\"PostsController\"} 5\nhttp_requests_total{controller=\"CommentsController\"} 3",
  )
}

///|
test "deployment helpers describe production process topology" {
  let processes = [
    web_process("web", "moon run cmd/main", 2, ["PORT", "DATABASE_URL"]),
    worker_process(
      "worker",
      "moon run examples/rails_ops",
      4,
      ["default", "mailers"],
      ["DATABASE_URL", "REDIS_URL"],
    ),
    cable_process("cable", "moon run cmd/main", 1, ["REDIS_URL"]),
    scheduler_process("scheduler", "moon run examples/production_stack", [
      "DATABASE_URL",
    ]),
    release_process("release", "moon run examples/orm_migration", [
      "DATABASE_URL",
    ]),
  ]
  let tasks = [
    release_task(
      name="db:migrate",
      command="moon run examples/orm_migration",
      required=true,
    ),
    release_task(
      name="db:seed",
      command="moon run examples/rails_ops",
      required=false,
    ),
  ]

  assert_true(process_summary(processes).contains("worker role=worker"))
  assert_true(env_keys_summary(processes[0]).contains("DATABASE_URL"))
  assert_true(release_summary(tasks).contains("db:migrate"))

  let injected_process = worker_process(
    "worker\nrelease",
    "moon run examples/rails_ops\nrelease: forged",
    0,
    ["default\nmailers"],
    ["DATABASE_URL\nOTHER"],
  )
  let injected_summary = process_summary([injected_process])
  let injected_env = env_keys_summary(injected_process)
  let injected_release = release_summary([
    release_task(
      name="db\nmigrate",
      command="moon run examples/orm_migration\nset -x",
      required=true,
    ),
  ])

  assert_eq(injected_process.concurrency, 1)
  assert_false(injected_summary.contains("\nrelease"))
  assert_false(injected_env.contains("\nOTHER"))
  assert_false(injected_release.contains("\nset -x"))
  assert_true(
    injected_summary.contains(
      "worker release role=worker x1 queues=default mailers cmd=moon run examples/rails_ops release: forged",
    ),
  )
}
