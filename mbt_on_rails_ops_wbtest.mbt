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
        mbtv_path("examples/demo_blog/views/mailer/welcome.html.mbtv"),
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
        mbtv_path("examples/resource_app/views/components/note_counter.mbtv"),
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
      mbtv_path("examples/resource_app/views/pages/notes/index.mbtv"),
      "Notes",
      with_contract(
        server_component(
          "NotesIndexPage",
          mbtv_path("examples/resource_app/views/pages/notes/index.mbtv"),
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
  assert_true(demo.cable_table().contains("PostsChannel"))
  assert_true(demo.middleware_table().contains("security_headers"))
  assert_true(demo.fixture_table().contains("fixtures users"))
  assert_true(demo.seed_table().contains("seed bootstrap"))
  assert_true(demo.job_table().contains("posts.reindex"))
  assert_true(demo.mailer_table().contains("SessionMailer"))
  assert_true(demo.cache_table().contains("cache pages"))
}
