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
  assert_true(remember.signed)
  assert_true(cookie_header(remember).contains("Max-Age="))
  assert_eq(transient.name, config.session_cookie)
  assert_false(cookie_header(transient).contains("Max-Age="))
  assert_true(cookie_header(transient).contains("SameSite=Lax"))
  match
    verify_signed_cookie_value(
      config.session_cookie,
      transient.value,
      config.secret_key_base,
    ) {
    Some(value) => assert_eq(value, session.id)
    None => assert_true(false)
  }
}

///|
test "cookie stores and forgery strategies stay explicit and type safe" {
  let config = default_auth_config()
  let session = issue_session("7", "browser")
  let store = session_store_for_config(config~, remember_me=false)
  let remember_store = session_store_for_config(config~, remember_me=true)
  let cache_store = cache_session_store(
    key="_cache_session",
    expire_after_seconds=Some(120),
  )
  let redis_store = redis_session_store(
    key="_redis_session",
    same_site=cookie_same_site_none(),
  )
  let unsigned_signed_store = cookie_session_store(key="_unsafe_session")
  let disabled = disabled_session_store()

  assert_true(session_store_summary(store).contains("store=cookie"))
  assert_eq(remember_store.expire_after_seconds, Some(60 * 60 * 24 * 30))
  assert_true(session_store_summary(cache_store).contains("store=cache"))
  assert_eq(redis_store.same_site, cookie_same_site_none())
  assert_true(session_store_summary(disabled).contains("store=disabled"))

  let signed = signed_cookie(
    name="preview",
    value="token-1",
    secret=config.secret_key_base,
    domain=Some("example.com"),
    max_age_seconds=Some(60),
    expires_at=Some("Wed, 26 Mar 2026 10:00:00 GMT"),
  )
  assert_true(cookie_header(signed).contains("Domain=example.com"))
  assert_true(
    cookie_header(signed).contains("Expires=Wed, 26 Mar 2026 10:00:00 GMT"),
  )
  let injected = signed_cookie(
    name="preview\r\nset-cookie: forged",
    value="token-1\r\nx: y",
    secret=config.secret_key_base,
    domain=Some("example.com\r\nx: y"),
    expires_at=Some("Wed, 26 Mar 2026 10:00:00 GMT\r\nset-cookie: forged"),
  )
  let injected_header = cookie_header(injected)
  assert_false(injected_header.contains("\r"))
  assert_false(injected_header.contains("\n"))
  assert_false(injected_header.contains("set-cookie: forged"))
  assert_false(injected_header.contains("x: y"))
  match
    verify_signed_cookie_value("preview", signed.value, config.secret_key_base) {
    Some(value) => assert_eq(value, "token-1")
    None => assert_true(false)
  }
  assert_eq(
    verify_signed_cookie_value("preview", signed.value, "wrong-secret"),
    None,
  )

  let parsed = parse_cookie_header("preview=one; session=two; theme=dark")
  assert_eq(find_cookie(parsed, "session"), Some("two"))
  assert_eq(find_cookie(parsed, "missing"), None)
  assert_true(
    sign_cookie_value("preview", "token-1", config.secret_key_base).contains(
      "--",
    ),
  )
  let unsigned_signed_cookie = session_cookie_with_store(
    store=unsigned_signed_store,
    session~,
  )
  assert_eq(unsigned_signed_cookie.value, "")
  let unsigned_signed_request = append_request_header(
    request(
      verb=http_get(),
      path="/",
      query=[],
      form=[],
      session_id=None,
      body="",
    ),
    "cookie",
    "_unsafe_session=" + session.id,
  )
  assert_eq(
    request_session_id(unsigned_signed_request, unsigned_signed_store),
    None,
  )

  assert_eq(forgery_strategy_summary(request_forgery_exception()), "exception")
  match
    protect_from_forgery(
      Some(session),
      Some("wrong"),
      request_forgery_null_session(),
    ) {
    NullSession => ()
    _ => assert_true(false)
  }
  match
    protect_from_forgery(
      Some(session),
      Some("wrong"),
      request_forgery_reset_session(),
    ) {
    ResetSession => ()
    _ => assert_true(false)
  }
  match
    protect_from_forgery(
      Some(session),
      Some("wrong"),
      request_forgery_exception(),
    ) {
    Rejected(message) => assert_eq(message, "invalid_csrf_token")
    _ => assert_true(false)
  }
  match
    protect_from_forgery(
      Some(session),
      Some(session.csrf_token),
      request_forgery_exception(),
    ) {
    Verified(Some(current)) => assert_eq(current.id, session.id)
    _ => assert_true(false)
  }
}

///|
test "json api and probe helpers preserve statuses and metadata" {
  let healthy = health_response([health_check(name="app", ok=true, detail="ok")])
  let empty_probe = readiness_response([])
  let degraded = readiness_response([
    health_check(name="db", ok=false, detail="down"),
  ])
  let metrics = metrics_response("# TYPE requests_total counter")
  let ok = json_api_ok("posts", "42", [("title", "MoonBit")])
  let error = json_api_error(404, "not_found", "missing")

  assert_eq(healthy.status, 200)
  assert_eq(empty_probe.status, 503)
  assert_true(render_response_body(empty_probe.body).contains("degraded"))
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
  let strict_numbers = json_api_document(
    "posts",
    "42",
    [("bad", "1.2.3"), ("dash", "-"), ("leading", "01"), ("ok", "1.5e2")],
    [],
  )
  let strict_log = json_log(
    log_event("info", "numeric", None, [("bad", "--1"), ("ok", "-2.5")]),
  )
  let without_meta = json_api_document("posts", "42", [("title", "MoonBit")], [])
  assert_true(with_meta.contains("\"meta\""))
  assert_true(strict_numbers.contains("\"bad\": \"1.2.3\""))
  assert_true(strict_numbers.contains("\"dash\": \"-\""))
  assert_true(strict_numbers.contains("\"leading\": \"01\""))
  assert_true(strict_numbers.contains("\"ok\": 1.5e2"))
  assert_true(strict_log.contains("\"bad\": \"--1\""))
  assert_true(strict_log.contains("\"ok\": -2.5"))
  assert_false(without_meta.contains("\"meta\""))
}

///|
test "prometheus rendering sanitizes unsafe metric and label identifiers" {
  let rendered = render_prometheus(
    with_metric(
      metrics_registry(),
      counter(
        "9bad.metric\n# HELP injected",
        [
          ("bad-label\nname", "value"),
          ("9tenant", "prod"),
          ("valid_label", "ok"),
        ],
        7,
      ),
    ),
  )
  assert_true(rendered.contains("# TYPE _9bad_metric___HELP_injected counter"))
  assert_true(
    rendered.contains(
      "_9bad_metric___HELP_injected{bad_label_name=\"value\",_9tenant=\"prod\",valid_label=\"ok\"} 7",
    ),
  )
  assert_false(rendered.contains("\n# HELP injected"))
  assert_false(rendered.contains("bad-label"))
}

///|
test "metrics and secrets helpers expose environment safe summaries" {
  let registry = with_metric(
    increment_metric(
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
      "db_pool_available",
      [],
      1,
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
  assert_eq(metric_value(registry, "db_pool_available", []), 5)
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
    secret_var(
      name="PUBLIC_BANNER",
      value=Some("example.com\nDATABASE_URL=oops"),
      required=false,
      sensitive=false,
    ),
    secret_var(
      name="BAD-NAME",
      value=Some("bad"),
      required=false,
      sensitive=false,
    ),
    secret_var(name="SMTP_PASSWORD", value=None, required=true, sensitive=true),
    secret_var(name="API_TOKEN", value=Some(""), required=true, sensitive=true),
    secret_var(
      name="SECRET_KEY_BASE",
      value=Some("   "),
      required=true,
      sensitive=true,
    ),
  ])
  assert_false(secrets_valid(secrets))
  assert_true(masked_secret_summary(secrets).contains("SHORT=****"))
  assert_true(masked_secret_summary(secrets).contains("DATABASE_URL=po****od"))
  assert_true(
    masked_secret_summary(secrets).contains("PUBLIC_HOST=example.com"),
  )
  let preview = dotenv_preview(secrets)
  assert_true(preview.contains("PUBLIC_HOST=example.com"))
  assert_true(
    preview.contains("PUBLIC_BANNER=\"example.com\\nDATABASE_URL=oops\""),
  )
  assert_true(preview.contains("DATABASE_URL=<redacted>"))
  assert_false(preview.contains("\nDATABASE_URL=oops"))
  assert_false(preview.contains("BAD-NAME"))
  assert_false(preview.contains("postgres://app:secret@db/prod"))
  assert_false(preview.contains("SMTP_PASSWORD"))
  assert_false(preview.contains("API_TOKEN"))
  assert_false(preview.contains("SECRET_KEY_BASE"))
  assert_eq(missing_secrets(secrets)[0], "SMTP_PASSWORD")
  assert_eq(missing_secrets(secrets)[1], "API_TOKEN")
  assert_eq(missing_secrets(secrets)[2], "SECRET_KEY_BASE")
  match secret_value(secrets, "PUBLIC_HOST") {
    Some(value) => assert_eq(value, "example.com")
    None => assert_true(false)
  }
}
