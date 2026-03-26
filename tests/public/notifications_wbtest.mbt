///|
test "notifications capture cache operations with Rails-style names" {
  let store = cache_store("pages")
  let (result, recorded) = cache_fetch_with_notifications(
    store=store,
    key="posts:index",
    fallback="{\"posts\":[]}",
    version=None,
    expires_at=None,
    tags=["posts", "pages"],
    now=Some("2026-03-26T00:00:00Z"),
    notifications=notifications(),
  )

  assert_false(result.hit)
  assert_eq(recorded.named("cache_read.active_support").length(), 1)
  assert_eq(recorded.named("cache_generate.active_support").length(), 1)
  assert_eq(recorded.named("cache_write.active_support").length(), 1)
  assert_eq(recorded.prefixed("cache_").length(), 3)
  match recorded.named("cache_read.active_support")[0].payload_value("hit") {
    Some(value) => assert_eq(value, "false")
    None => assert_true(false)
  }
}

///|
test "notifications capture job and mailer instrumentation" {
  let reindex = job(
    "posts.reindex",
    "default",
    [("id", "String")],
    3,
    None,
  )
  let (queue, enqueue_events) = enqueue_now_with_notifications(
    queue=job_queue("default"),
    definition=reindex,
    payload=[("id", "42")],
    notifications=notifications(),
  )
  assert_eq(enqueue_events.named("enqueue.active_job").length(), 1)

  let (retried, retry_events) = retry_job_with_notifications(
    job=queue.jobs[0],
    next_run_at="2026-03-26T09:00:00Z",
    notifications=notifications(),
  )
  match retried {
    Some(_) => assert_true(true)
    None => assert_true(false)
  }
  assert_eq(retry_events.named("enqueue_retry.active_job").length(), 1)

  let (delivery, mail_events) = compose_mail_with_notifications(
    mailer=mailer(
      "SessionMailer",
      "noreply@example.com",
      None,
      [
        mail_template(
          "welcome",
          "Welcome",
          mbtv_path("examples/demo_blog/views/mailer/welcome.html.mbtv"),
          None,
        ),
      ],
    ),
    action_name="welcome",
    to=["hello@example.com"],
    assigns=[("name", "MoonBit")],
    notifications=notifications(),
  )
  match delivery {
    Some(_) => assert_true(true)
    None => assert_true(false)
  }
  assert_eq(mail_events.named("process.action_mailer").length(), 1)
}

///|
test "notifications capture controller and view rendering events" {
  let page = page_module(
    route_name="home",
    route_path="/",
    file_path=mbtv_path("examples/demo_blog/views/pages/home.mbtv"),
    title="Home",
    component=server_component(
      name="HomePage",
      source_path=mbtv_path("examples/demo_blog/views/pages/home.mbtv"),
      props=[],
    ),
  )
  let app = app_named("instrumented")
    .with_page(page)
    .with_route(
      route(
        name="home",
        verb=http_get(),
        path="/",
        controller="PagesController",
        action="home",
        page_name=Some("home"),
      ),
    )

  let (response, recorded) = handle_request_with_notifications(
    app=app,
    incoming=request(
      verb=http_get(),
      path="/",
      query=[],
      form=[],
      session_id=None,
      body="",
    ),
    notifications=notifications(),
  )

  assert_eq(response.status, 200)
  assert_eq(recorded.named("start_processing.action_controller").length(), 1)
  assert_eq(recorded.named("process_action.action_controller").length(), 1)
  assert_eq(recorded.named("render_template.action_view").length(), 1)
  match recorded.named("process_action.action_controller")[0].payload_value("controller") {
    Some(value) => assert_eq(value, "PagesController")
    None => assert_true(false)
  }
}
