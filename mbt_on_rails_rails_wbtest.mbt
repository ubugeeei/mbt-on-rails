///|
test "strong params filter scoped attributes" {
  let parameters = merge_params([("id", "42")], [("page", "1")], [
    ("post.title", "MoonBit"),
    ("post.body", "Typed islands"),
    ("post.admin", "true"),
  ])

  match require_scope(parameters, "post") {
    Some(scoped) =>
      match param_value(scoped, "title") {
        Some(title) => assert_eq(title, "MoonBit")
        None => assert_true(false)
      }
    None => assert_true(false)
  }

  let permitted = permit_scope(parameters, "post", ["title", "body"])
  assert_eq(permitted_attributes(permitted).length(), 2)
  assert_true(permitted.rejected.contains("admin"))
  assert_true(permitted_summary(permitted).contains("scope=post"))
}

///|
test "jobs mailers and cache support rails style workflows" {
  let mailer = mailer(
    "AnnouncementMailer",
    "noreply@example.com",
    Some("mailer"),
    [
      mail_template(
        "launch",
        "Launch update",
        "examples/demo_blog/views/mailer/welcome.html.mbtv",
        Some("examples/demo_blog/views/mailer/welcome.text"),
      ),
    ],
  )

  let queue = match
    compose_mail(mailer, "launch", ["team@example.com"], [
      ("headline", "Ship it"),
    ]) {
    Some(delivery) => enqueue_delivery(job_queue("mailers"), delivery, None)
    None => job_queue("mailers")
  }

  assert_true(job_summary(queue).contains("mailers.deliver"))
  match retry_job(queue.jobs[0], "2026-03-26T09:00:00Z") {
    Some(job) => assert_eq(job.attempts, 1)
    None => assert_true(false)
  }

  let fetched = cache_fetch(
    cache_store("pages"),
    cache_key(["posts", "index"]),
    "{\"posts\":[]}",
    Some("v1"),
    Some("2026-03-26T00:00:00Z"),
    ["posts", "pages"],
    Some("2026-03-25T00:00:00Z"),
  )
  assert_false(fetched.hit)
  match
    cache_read(
      fetched.store,
      cache_key(["posts", "index"]),
      Some("2026-03-25T00:00:00Z"),
    ) {
    Some(value) => assert_eq(value, "{\"posts\":[]}")
    None => assert_true(false)
  }
}

///|
test "component contracts surface server client boundaries in manifests" {
  let action = server_action(
    "posts.create",
    "/_actions/posts.create",
    [("title", "String"), ("body", "String")],
    "PostPayload",
    true,
  )
  let island = with_contract(
    with_fallback(
      client_component(
        "NoteCounter",
        "examples/resource_app/views/components/note_counter.mbtv",
        [("initial", "1")],
        hydrate_visible(),
      ),
      "<button type=\"button\">1</button>",
    ),
    client_contract([prop_contract("initial", "Int", true, "Initial count")]),
  )
  let page = with_island(
    page_module(
      "notes_index",
      "/notes",
      "examples/resource_app/views/pages/notes/index.mbtv",
      "Notes",
      with_contract(
        server_component(
          "NotesIndexPage",
          "examples/resource_app/views/pages/notes/index.mbtv",
          [],
        ),
        server_contract([], true),
      ),
    ),
    island,
  )
  let rendered = render_page(page, [], [], [action])

  assert_true(
    rendered.component_manifest_json.contains("\"boundary\": \"client\""),
  )
  assert_true(
    rendered.component_manifest_json.contains("\"transport\": \"json\""),
  )
  assert_true(rendered.html.contains("data-mbor-boundary=\"client\""))
  assert_true(rendered.html.contains("data-mbor-fallback"))
  assert_true(
    render_server_action_manifest([action]).contains("\"input_fields\""),
  )

  let demo = demo_blog_app()
  assert_true(demo.middleware_table().contains("security_headers"))
  assert_true(demo.fixture_table().contains("fixtures users"))
  assert_true(demo.seed_table().contains("seed bootstrap"))
  assert_true(demo.job_table().contains("posts.reindex"))
  assert_true(demo.mailer_table().contains("SessionMailer"))
  assert_true(demo.cache_table().contains("cache pages"))
}

///|
test "middleware fixtures seeds and turbo streams behave like rails runtime helpers" {
  let stack = [
    with_response_header(
      middleware("security", None, [], [], [], None),
      "x-frame-options",
      "DENY",
    ),
    halt_with_text("maintenance", "/admin", [http_get()], 503, "down"),
  ]
  let admin_request = request(http_get(), "/admin", [], [], None, "")
  let request_result = apply_request_middleware(stack, admin_request)
  match request_result.1 {
    Some(response) => assert_eq(response.status, 503)
    None => assert_true(false)
  }
  let passthrough = apply_response_middleware(
    stack,
    request(http_get(), "/posts", [], [], None, ""),
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
}
