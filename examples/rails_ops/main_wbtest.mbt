///|
test "rails ops example primitives produce stable summaries and runtime behavior" {
  let parameters = @mbor.merge_params([("id", "42")], [("page", "1")], [
    ("post.title", "MoonBit on Rails"),
    ("post.body", "Typed islands"),
    ("post.admin", "true"),
  ])
  let permitted = @mbor.permit_scope(parameters, "post", ["title", "body"])
  assert_eq(@mbor.permitted_attributes(permitted).length(), 2)
  assert_true(permitted.rejected.contains("admin"))

  let channel = @mbor.cable_channel("PostsChannel", "posts", ["post_id"])
  let broadcast = @mbor.broadcast_turbo(channel, [
    @mbor.append_stream("posts", "<li>Broadcasted</li>"),
  ])
  assert_true(@mbor.cable_summary([channel]).contains("PostsChannel"))
  assert_true(@mbor.broadcast_summary(broadcast).contains("turbo-stream"))

  let stack = [
    @mbor.with_response_header(
      @mbor.middleware("security", None, [], [], [], None),
      "x-frame-options",
      "DENY",
    ),
    @mbor.halt_with_text(
      "maintenance",
      "/admin",
      [@mbor.http_get()],
      503,
      "down",
    ),
  ]
  let result = @mbor.apply_request_middleware(
    stack,
    @mbor.request(
      verb=@mbor.http_get(),
      path="/admin",
      query=[],
      form=[],
      session_id=None,
      body="",
    ),
  )
  match result.1 {
    Some(response) => assert_eq(response.status, 503)
    None => assert_true(false)
  }

  let fixtures = @mbor.fixture_set("users", "users", [
    @mbor.fixture_row(
      "alice",
      @mbor.record("users", [("id", "1"), ("email", "alice@example.com")]),
    ),
  ])
  let seeded = @mbor.apply_seed(
    @mbor.load_fixture_set(@mbor.empty_memory_database(), fixtures),
    @mbor.seed_plan(
      "bootstrap",
      [@mbor.record("users", [("id", "2"), ("email", "bob@example.com")])],
      [],
    ),
  )
  assert_eq(@mbor.find_records(seeded, "users", "id", "1").length(), 1)
  assert_eq(@mbor.find_records(seeded, "users", "id", "2").length(), 1)
}

///|
test "rails ops example covers jobs mailers turbo cache and main smoke" {
  let announcement_mailer = @mbor.mailer(
    name="AnnouncementMailer",
    from="noreply@example.com",
    layout_name=Some("mailer"),
    templates=[
      @mbor.mail_template(
        action_name="launch",
        subject="Launch update",
        html_path=@mbor.mbtv_path(
          "examples/demo_blog/views/mailer/welcome.html.mbtv",
        ),
        text_path=Some("examples/demo_blog/views/mailer/welcome.text"),
      ),
    ],
  )
  match
    @mbor.compose_mail(announcement_mailer, "launch", ["team@example.com"], [
      ("headline", "mbt on rails ships more Rails surfaces"),
    ]) {
    Some(delivery) => {
      let queue = @mbor.enqueue_delivery(
        @mbor.job_queue(name="mailers"),
        delivery,
        None,
      )
      assert_true(@mbor.job_summary(queue).contains("mailers.deliver"))
      assert_true(@mbor.mailer_summary(announcement_mailer).contains("launch"))
    }
    None => assert_true(false)
  }

  let body = @mbor.render_turbo_stream([
    @mbor.append_stream("posts", "<li>New post</li>"),
    @mbor.replace_stream("flash", "<div>Saved</div>"),
  ])
  assert_true(body.contains("turbo-stream"))

  let cache_result = @mbor.cache_fetch(
    @mbor.cache_store("pages"),
    @mbor.cache_key(["posts", "index"]),
    "{\"posts\":[]}",
    Some("v1"),
    Some("2026-03-26T00:00:00Z"),
    ["posts", "pages"],
    Some("2026-03-25T00:00:00Z"),
  )
  assert_false(cache_result.hit)
  assert_true(@mbor.cache_summary(cache_result.store).contains("cache pages"))

  print_params_example()
  print_cable_example()
  print_middleware_example()
  print_fixture_example()
  print_job_and_mailer_example()
  print_turbo_example()
  print_cache_example()
  run_example()
  assert_true(true)
}
