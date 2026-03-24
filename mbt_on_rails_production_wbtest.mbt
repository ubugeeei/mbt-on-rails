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
      "DATABASE_URL",
      Some("postgres://app:secret@db/prod"),
      true,
      true,
    ),
    secret_var("SMTP_PASSWORD", None, true, true),
  ])
  assert_false(secrets_valid(secrets))
  assert_true(masked_secret_summary(secrets).contains("po****od"))
  assert_eq(missing_secrets(secrets)[0], "SMTP_PASSWORD")

  let healthy = health_response([health_check("app", true, "ok")])
  let metrics = metrics_response(render_prometheus(registry))
  let api_ok = json_api_ok("posts", "42", [("title", "MoonBit")])
  let api_error = json_api_error(404, "not_found", "missing")

  assert_eq(healthy.status, 200)
  assert_eq(metrics.headers[0].1, "text/plain; version=0.0.4; charset=utf-8")
  assert_true(render_response_body(api_ok.body).contains("\"type\": \"posts\""))
  assert_true(
    render_response_body(api_error.body).contains("\"code\": \"not_found\""),
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
    release_task("db:migrate", "moon run examples/orm_migration", true),
    release_task("db:seed", "moon run examples/rails_ops", false),
  ]

  assert_true(process_summary(processes).contains("worker role=worker"))
  assert_true(env_keys_summary(processes[0]).contains("DATABASE_URL"))
  assert_true(release_summary(tasks).contains("db:migrate"))
}
