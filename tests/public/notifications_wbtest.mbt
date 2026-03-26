///|
test "notifications capture cache operations with Rails-style names" {
  let store = cache_store("pages")
  let (result, recorded) = cache_fetch_with_notifications(
    store~,
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
    name="posts.reindex",
    queue="default",
    argument_types=[("id", "String")],
    retry_limit=3,
    unique_key=None,
  )
  let (queue, enqueue_events) = enqueue_now_with_notifications(
    queue=job_queue(name="default"),
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

  let policy_job = enqueued_job(
    definition=job(name="search.sync", queue="default", argument_types=[
        ("id", "String"),
      ])
      .retry_on("TimeoutError", attempts=2, wait=fixed_wait(seconds=5))
      .discard_on("DeserializationError"),
    payload=[("id", "7")],
    run_at="",
    attempts=0,
  )
  let (handled_retry, handled_retry_events) = handle_job_failure_with_notifications(
    job=policy_job,
    error_name="TimeoutError",
    now="2026-03-26T09:00:00Z",
    notifications=notifications(),
  )
  match handled_retry {
    Retried(next_job) => assert_eq(next_job.run_at, "2026-03-26T09:00:05Z")
    _ => assert_true(false)
  }
  assert_eq(handled_retry_events.named("enqueue_retry.active_job").length(), 1)

  let (handled_discard, handled_discard_events) = handle_job_failure_with_notifications(
    job=policy_job,
    error_name="DeserializationError",
    now="2026-03-26T09:00:00Z",
    notifications=notifications(),
  )
  match handled_discard {
    Discarded(_) => assert_true(true)
    _ => assert_true(false)
  }
  assert_eq(handled_discard_events.named("discard.active_job").length(), 1)

  let stopped_job = enqueued_job(
    definition=job(name="search.sync", queue="default", argument_types=[
        ("id", "String"),
      ])
      .retry_on("TimeoutError", attempts=2, wait=fixed_wait(seconds=5))
      .discard_on("DeserializationError"),
    payload=[("id", "7")],
    run_at="",
    attempts=1,
  )
  let (handled_stopped, handled_stopped_events) = handle_job_failure_with_notifications(
    job=stopped_job,
    error_name="TimeoutError",
    now="2026-03-26T09:00:00Z",
    notifications=notifications(),
  )
  match handled_stopped {
    RetryStopped(_) => assert_true(true)
    _ => assert_true(false)
  }
  assert_eq(
    handled_stopped_events.named("retry_stopped.active_job").length(),
    1,
  )

  let (delivery, mail_events) = compose_mail_with_notifications(
    mailer=mailer(
      name="SessionMailer",
      from="noreply@example.com",
      layout_name=None,
      templates=[
        mail_template(
          action_name="welcome",
          subject="Welcome",
          html_path=mbtv_path(
            "examples/demo_blog/views/mailer/welcome.html.mbtv",
          ),
          text_path=None,
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
    app~,
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
  match
    recorded.named("process_action.action_controller")[0].payload_value(
      "controller",
    ) {
    Some(value) => assert_eq(value, "PagesController")
    None => assert_true(false)
  }
}
