///|
test "middleware fixtures seeds and turbo streams behave like rails runtime helpers" {
  let stack = [
    middleware("security", None, [], [], [], None).with_response_header(
      "x-frame-options", "DENY",
    ),
    halt_with_text("maintenance", "/admin", [http_get()], 503, "down"),
  ]
  let admin_request = request(
    verb=http_get(),
    path="/admin",
    query=[],
    form=[],
    session_id=None,
    body="",
  )
  let request_result = apply_request_middleware(stack, admin_request)
  match request_result.1 {
    Some(response) => assert_eq(response.status, 503)
    None => assert_true(false)
  }
  let passthrough = apply_response_middleware(
    stack,
    request(
      verb=http_get(),
      path="/posts",
      query=[],
      form=[],
      session_id=None,
      body="",
    ),
    ok_text("ok"),
  )
  assert_true(passthrough.headers.contains(("x-frame-options", "DENY")))

  let fixtures = fixture_set("users", "users", [
    fixture_row(
      "alice",
      record("users", [("id", "1"), ("email", "a@example.com")]),
    ),
  ])
  let seeded = apply_seed(
    load_fixture_set(empty_memory_database(), fixtures),
    seed_plan(
      "bootstrap",
      [record("users", [("id", "2"), ("email", "b@example.com")])],
      [],
    ),
  )
  assert_eq(find_records(seeded, "users", "id", "1").length(), 1)
  assert_eq(find_records(seeded, "users", "id", "2").length(), 1)

  let turbo = ok_turbo_stream([
    append_stream("posts", "<li>New</li>"),
    remove_stream("stale_post"),
  ])
  assert_true(render_response_body(turbo.body).contains("turbo-stream"))
  assert_eq(turbo.headers[0].1, "text/vnd.turbo-stream.html; charset=utf-8")

  let channel = cable_channel("PostsChannel", "posts", ["post_id"])
  let broadcast = broadcast_turbo(channel, [
    append_stream("posts", "<li>Broadcast</li>"),
  ])
  assert_true(cable_summary([channel]).contains("PostsChannel"))
  assert_true(broadcast_summary(broadcast).contains("text/vnd.turbo-stream"))
}

///|
test "middleware path prefixes match only on segment boundaries" {
  let stack = [
    middleware("admin", Some("/admin"), [], [], [], None).with_response_header(
      "x-admin", "yes",
    ),
    halt_with_text("admin-halt", "/admin", [http_get()], 503, "down"),
  ]
  let administrator = request(
    verb=http_get(),
    path="/administrator",
    query=[],
    form=[],
    session_id=None,
    body="",
  )
  let admin_post = request(
    verb=http_get(),
    path="/admin/posts",
    query=[],
    form=[],
    session_id=None,
    body="",
  )

  let miss = apply_request_middleware(stack, administrator)
  match miss.1 {
    Some(_) => assert_true(false)
    None => assert_true(true)
  }
  let missed_response = apply_response_middleware(
    stack,
    administrator,
    ok_text("ok"),
  )
  assert_false(missed_response.headers.contains(("x-admin", "yes")))

  let hit = apply_request_middleware(stack, admin_post)
  match hit.1 {
    Some(response) => assert_eq(response.status, 503)
    None => assert_true(false)
  }
}

///|
test "halted requests apply only response middleware reached before halt" {
  let halted_app = app_named("halted")
    .with_middleware(
      middleware("early", None, [], [], [], None).with_response_header(
        "x-early", "yes",
      ),
    )
    .with_middleware(
      halt_with_text("halt", "/admin", [http_get()], 503, "down").with_response_header(
        "x-halt", "yes",
      ),
    )
    .with_middleware(
      middleware("late", None, [], [], [], None).with_response_header(
        "x-late", "no",
      ),
    )
  let response = handle_request(
    halted_app,
    request(
      verb=http_get(),
      path="/admin",
      query=[],
      form=[],
      session_id=None,
      body="",
    ),
  )

  assert_eq(response.status, 503)
  assert_true(response.headers.contains(("x-early", "yes")))
  assert_true(response.headers.contains(("x-halt", "yes")))
  assert_false(response.headers.contains(("x-late", "no")))
}

///|
test "production helpers render config health and logs" {
  let config = default_production_config()
  let checks = [
    health_check(name="database", ok=true, detail="ok"),
    health_check(name="redis", ok=false, detail="timeout"),
  ]
  let rule = rate_limit_rule("api", "/api", 60, 60)
  let event = log_event("info", "request completed", Some("req_1"), [
    ("path", "/api/posts"),
    ("status", "200"),
  ])

  assert_true(config_summary(config).contains("production"))
  assert_true(render_health_json(checks).contains("\"status\": \"degraded\""))
  assert_true(rate_limit_summary(rule).contains("60/60s"))
  assert_true(rate_limited(rule, 61))
  assert_true(json_log(event).contains("\"request_id\": \"req_1\""))
}
