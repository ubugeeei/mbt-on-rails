///|
/// Prints a Strong Parameters-style filtering example.
fn print_params_example() -> Unit {
  let parameters = @mbor.merge_params([("id", "42")], [("page", "1")], [
    ("post.title", "MoonBit on Rails"),
    ("post.body", "Typed islands"),
    ("post.admin", "true"),
  ])
  let permitted = @mbor.permit_scope(parameters, "post", ["title", "body"])
  println("Params")
  println(@mbor.permitted_summary(permitted))
  println("")
}

///|
/// Prints an Action Cable-style channel and broadcast example.
fn print_cable_example() -> Unit {
  let channel = @mbor.cable_channel("PostsChannel", "posts", ["post_id"])
  let broadcast = @mbor.broadcast_turbo(channel, [
    @mbor.append_stream("posts", "<li>Broadcasted</li>"),
  ])
  println("Cable")
  println(@mbor.cable_summary([channel]))
  println(@mbor.broadcast_summary(broadcast))
  println("")
}

///|
/// Prints a Rack-style middleware example.
fn print_middleware_example() -> Unit {
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
  println("Middleware")
  println(@mbor.middleware_summary(stack))
  println("")
}

///|
/// Prints a fixtures and seed example.
fn print_fixture_example() -> Unit {
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
  println("Fixtures")
  println(@mbor.fixture_summary(fixtures))
  println(@mbor.seed_summary(@mbor.seed_plan("bootstrap", [], [])))
  let alice = @mbor.find_records(seeded, "users", "id", "1").length()
  let bob = @mbor.find_records(seeded, "users", "id", "2").length()
  println("users loaded = " + (alice + bob).to_string())
  println("")
}

///|
/// Prints an Active Job plus Action Mailer example.
fn print_job_and_mailer_example() -> Unit {
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
      println("Jobs")
      println(@mbor.job_summary(queue))
      println("")
      println("Mailers")
      println(@mbor.mailer_summary(announcement_mailer))
      println("")
    }
    None => ()
  }
}

///|
/// Prints a Turbo Stream rendering example.
fn print_turbo_example() -> Unit {
  let body = @mbor.render_turbo_stream([
    @mbor.append_stream("posts", "<li>New post</li>"),
    @mbor.replace_stream("flash", "<div>Saved</div>"),
  ])
  println("Turbo")
  println(body)
  println("")
}

///|
/// Prints a cache read-through example.
fn print_cache_example() -> Unit {
  let result = @mbor.cache_fetch(
    @mbor.cache_store("pages"),
    @mbor.cache_key(["posts", "index"]),
    "{\"posts\":[]}",
    Some("v1"),
    Some("2026-03-26T00:00:00Z"),
    ["posts", "pages"],
    Some("2026-03-25T00:00:00Z"),
  )
  println("Cache")
  println(@mbor.cache_summary(result.store))
  println("")
}

///|
/// Runs the Rails operations example output.
fn run_example() -> Unit {
  println("Rails Ops Example")
  println("=================")
  println("")
  print_params_example()
  print_cable_example()
  print_middleware_example()
  print_fixture_example()
  print_job_and_mailer_example()
  print_turbo_example()
  print_cache_example()
}

///|
fn main {
  run_example()
}
