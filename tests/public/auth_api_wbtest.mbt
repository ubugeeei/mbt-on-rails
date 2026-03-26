///|
test "session helpers generate stable digests tokens and cookies" {
  let config = default_auth_config()
  let digest = digest_password("secret", "salt")
  assert_true(verify_password("secret", "salt", digest))
  assert_false(verify_password("nope", "salt", digest))

  let session = issue_session("7", "browser")
  assert_true(session.id.has_prefix("sess_"))
  assert_true(session.csrf_token.has_prefix("csrf_"))
  assert_true(csrf_valid(Some(session), Some(session.csrf_token)))
  assert_false(csrf_valid(Some(session), Some("wrong")))
  assert_false(csrf_valid(None, Some("wrong")))

  let reset = issue_password_reset(
    "7", "editor@example.com", "2026-03-25T10:00:00Z",
  )
  let verification = issue_email_verification(
    "7", "editor@example.com", "2026-03-25T10:00:00Z",
  )
  assert_true(reset.token.has_prefix("reset_"))
  assert_eq(reset.expires_at, "2026-03-25T10:00:00Z+15m")
  assert_true(verification.token.has_prefix("verify_"))
  assert_eq(verification.expires_at, "2026-03-25T10:00:00Z+24h")

  let remember = session_cookie(config~, session~, remember_me=true)
  let transient = session_cookie(config~, session~, remember_me=false)
  assert_eq(remember.name, config.remember_cookie)
  assert_true(cookie_header(remember).contains("Max-Age="))
  assert_eq(transient.name, config.session_cookie)
  assert_false(cookie_header(transient).contains("Max-Age="))
}

///|
test "json api and probe helpers preserve statuses and metadata" {
  let healthy = health_response([health_check(name="app", ok=true, detail="ok")])
  let degraded = readiness_response([
    health_check(name="db", ok=false, detail="down"),
  ])
  let metrics = metrics_response("# TYPE requests_total counter")
  let ok = json_api_ok("posts", "42", [("title", "MoonBit")])
  let error = json_api_error(404, "not_found", "missing")

  assert_eq(healthy.status, 200)
  assert_eq(degraded.status, 503)
  assert_eq(metrics.headers[0].1, "text/plain; version=0.0.4; charset=utf-8")
  assert_eq(ok.status, 200)
  assert_eq(error.status, 404)
  assert_true(
    render_response_body(error.body).contains("\"code\": \"not_found\""),
  )

  let with_meta = json_api_document("posts", "42", [("title", "MoonBit")], [
    ("cached", "true"),
  ])
  let without_meta = json_api_document("posts", "42", [("title", "MoonBit")], [])
  assert_true(with_meta.contains("\"meta\""))
  assert_false(without_meta.contains("\"meta\""))
}

///|
test "metrics and secrets helpers expose environment safe summaries" {
  let registry = with_metric(
    set_metric(
      increment_metric(
        metrics_registry(),
        "http_requests_total",
        [("controller", "PostsController")],
        2,
      ),
      "db_pool_available",
      [],
      4,
    ),
    counter("job_executions_total", [("queue", "default")], 8),
  )
  assert_eq(
    metric_value(registry, "http_requests_total", [
      ("controller", "PostsController"),
    ]),
    2,
  )
  assert_true(
    render_prometheus(registry).contains("# TYPE db_pool_available gauge"),
  )
  assert_true(metrics_summary(registry).contains("job_executions_total"))

  let secrets = secrets_config([
    secret_var(name="SHORT", value=Some("abc"), required=true, sensitive=true),
    secret_var(
      name="DATABASE_URL",
      value=Some("postgres://app:secret@db/prod"),
      required=true,
      sensitive=true,
    ),
    secret_var(
      name="PUBLIC_HOST",
      value=Some("example.com"),
      required=true,
      sensitive=false,
    ),
    secret_var(name="SMTP_PASSWORD", value=None, required=true, sensitive=true),
  ])
  assert_false(secrets_valid(secrets))
  assert_true(masked_secret_summary(secrets).contains("SHORT=****"))
  assert_true(masked_secret_summary(secrets).contains("DATABASE_URL=po****od"))
  assert_true(
    masked_secret_summary(secrets).contains("PUBLIC_HOST=example.com"),
  )
  assert_true(dotenv_preview(secrets).contains("PUBLIC_HOST=example.com"))
  assert_false(dotenv_preview(secrets).contains("SMTP_PASSWORD"))
  assert_eq(missing_secrets(secrets)[0], "SMTP_PASSWORD")
  match secret_value(secrets, "PUBLIC_HOST") {
    Some(value) => assert_eq(value, "example.com")
    None => assert_true(false)
  }
}
