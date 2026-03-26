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
    name="AnnouncementMailer",
    from="noreply@example.com",
    layout_name=Some("mailer"),
    templates=[
      mail_template(
        action_name="launch",
        subject="Launch update",
        html_path=mbtv_path("examples/demo_blog/views/mailer/welcome.html.mbtv"),
        text_path=Some("examples/demo_blog/views/mailer/welcome.text"),
      ),
    ],
  )

  let queue = match
    compose_mail(mailer, "launch", ["team@example.com"], [
      ("headline", "Ship it"),
    ]) {
    Some(delivery) =>
      enqueue_delivery(job_queue(name="mailers"), delivery, None)
    None => job_queue(name="mailers")
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
test "job failure policies support retry_on discard_on and queue overrides" {
  let definition = job(
      name="SearchIndexJob",
      queue="default",
      argument_types=[("id", "String")],
      retry_limit=0,
      unique_key=None,
    )
    .retry_on(
      "TimeoutError",
      attempts=3,
      wait=fixed_wait(seconds=5),
      queue=Some("low"),
    )
    .discard_on("DeserializationError", report=true)

  let current = enqueued_job(
    definition~,
    payload=[("id", "42")],
    run_at="",
    attempts=0,
  )

  match handle_job_failure(current, "TimeoutError", "2026-03-26T09:00:00Z") {
    Retried(next_job) => {
      assert_eq(next_job.queue, "low")
      assert_eq(next_job.attempts, 1)
      assert_eq(next_job.run_at, "2026-03-26T09:00:05Z")
    }
    _ => assert_true(false)
  }

  match
    handle_job_failure(current, "DeserializationError", "2026-03-26T09:00:00Z") {
    Discarded(discarded) => assert_eq(discarded.name, "SearchIndexJob")
    _ => assert_true(false)
  }

  let exhausted = enqueued_job(
    definition~,
    payload=[("id", "42")],
    run_at="",
    attempts=2,
  )
  match handle_job_failure(exhausted, "TimeoutError", "2026-03-26T09:00:00Z") {
    RetryStopped(stopped) => assert_eq(stopped.attempts, 2)
    _ => assert_true(false)
  }

  let slow = job(name="RemoteCallJob", queue="default", argument_types=[]).retry_on(
    "NetTimeout",
    attempts=4,
    wait=polynomially_longer(),
  )
  let pending = enqueued_job(definition=slow, payload=[], run_at="", attempts=1)
  match handle_job_failure(pending, "NetTimeout", "2026-03-26T09:00:00Z") {
    Retried(next_job) => assert_eq(next_job.run_at, "2026-03-26T09:00:18Z")
    _ => assert_true(false)
  }
}

///|
test "job adapters and serialized jobs preserve queue contracts" {
  let adapter = solid_queue_adapter(queue_prefix=Some("solid"))
  let definition = job(
    name="SearchIndexJob",
    queue="default",
    argument_types=[
      ("id", "String"),
      ("published", "Bool"),
      ("title", "String"),
    ],
    retry_limit=3,
    unique_key=Some("search:index"),
  )
  let queue = enqueue_at_with_adapter(
    job_queue(name="default"),
    definition,
    [("id", "42"), ("published", "true"), ("title", "MoonBit \"Rails\"")],
    "2026-03-27T09:00:00Z",
    adapter,
  )

  assert_eq(queue.name, "solid:default")
  assert_eq(queue.jobs[0].queue, "solid:default")
  assert_eq(queue.jobs[0].argument_types.length(), 3)
  assert_true(job_adapter_summary(adapter).contains("kind=solid_queue"))

  let serialized = serialize_job(queue.jobs[0], adapter)
  assert_true(serialized_job_summary(serialized).contains("via solid_queue"))
  assert_true(
    render_serialized_job(serialized).contains("\"queue\": \"solid:default\""),
  )

  match deserialize_payload(serialized.payload_json) {
    Some(payload) => {
      assert_eq(find_entry(payload, "id"), Some("42"))
      assert_eq(find_entry(payload, "published"), Some("true"))
      assert_eq(find_entry(payload, "title"), Some("MoonBit \"Rails\""))
    }
    None => assert_true(false)
  }

  match restore_enqueued_job(serialized) {
    Some(restored) => {
      assert_eq(restored.queue, "solid:default")
      assert_eq(restored.unique_key, Some("search:index"))
      assert_eq(restored.argument_types[1].1, "Bool")
      assert_eq(
        find_entry(restored.payload, "title"),
        Some("MoonBit \"Rails\""),
      )
    }
    None => assert_true(false)
  }
}

///|
test "component contracts surface server client boundaries in manifests" {
  let action = server_action(
    name="posts.create",
    route="/_actions/posts.create",
    input_fields=[("title", "String"), ("body", "String")],
    output_type="PostPayload",
    csrf_protected=true,
  )
  let island = with_contract(
    with_fallback(
      client_component(
        name="NoteCounter",
        source_path=mbtv_path(
          "examples/resource_app/views/components/note_counter.mbtv",
        ),
        props=[("initial", "1")],
        hydration=hydrate_visible(),
      ),
      "<button type=\"button\">1</button>",
    ),
    client_contract(props=[
      prop_contract(
        name="initial",
        type_name="Int",
        required=true,
        description="Initial count",
      ),
    ]),
  )
  let page = with_island(
    page_module(
      route_name="notes_index",
      route_path="/notes",
      file_path=mbtv_path("examples/resource_app/views/pages/notes/index.mbtv"),
      title="Notes",
      component=with_contract(
        server_component(
          name="NotesIndexPage",
          source_path=mbtv_path(
            "examples/resource_app/views/pages/notes/index.mbtv",
          ),
          props=[],
        ),
        server_contract(props=[], async_only=true),
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
