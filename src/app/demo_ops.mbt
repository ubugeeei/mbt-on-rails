///|
/// Builds the mailers configured by the demo app.
pub fn demo_mailers() -> Array[@mailer.MailerDefinition] {
  [demo_session_mailer()]
}

///|
/// Builds the job queues shown by the demo app.
pub fn demo_job_queues() -> Array[@job.JobQueue] {
  let default_queue = @job.enqueue_at(
    @job.enqueue_now(
      @job.job_queue("default"),
      @job.job(
        "posts.reindex",
        "default",
        [("resource", "String"), ("id", "String")],
        3,
        Some("posts:search"),
      ),
      [("resource", "posts"), ("id", "42")],
    ),
    @job.job("posts.publish", "default", [("id", "String")], 2, None),
    [("id", "42")],
    "2026-03-26T09:00:00Z",
  )
  let mailer_queue = match
    @mailer.compose_mail(
      demo_session_mailer(),
      "welcome",
      ["hello@example.com"],
      [("name", "MoonBit Rails")],
    ) {
    Some(delivery) =>
      @mailer.enqueue_delivery(@job.job_queue("mailers"), delivery, None)
    None => @job.job_queue("mailers")
  }
  [default_queue, mailer_queue]
}

///|
/// Builds the cache namespaces shown by the demo app.
pub fn demo_caches() -> Array[@cache.CacheStore] {
  [
    @cache.cache_write(
      @cache.cache_store("pages"),
      @cache.cache_key(["posts", "index"]),
      "{\"posts\": []}",
      Some("v1"),
      Some("2026-03-26T00:00:00Z"),
      ["pages", "posts"],
    ),
    @cache.cache_write(
      @cache.cache_store("fragments"),
      @cache.cache_key(["posts", "show", "42"]),
      "{\"likes\": 12}",
      Some("v2"),
      None,
      ["posts", "show"],
    ),
  ]
}

///|
/// Builds the session mailer used by the demo app.
fn demo_session_mailer() -> @mailer.MailerDefinition {
  @mailer.mailer("SessionMailer", "noreply@mbt-on-rails.dev", Some("mailer"), [
    @mailer.mail_template(
      "welcome",
      "Welcome to mbt on rails",
      "examples/demo_blog/views/mailer/welcome.html.mbtv",
      Some("examples/demo_blog/views/mailer/welcome.text"),
    ),
    @mailer.mail_template(
      "password_reset",
      "Reset your password",
      "examples/demo_blog/views/mailer/password_reset.html.mbtv",
      Some("examples/demo_blog/views/mailer/password_reset.text"),
    ),
  ])
}
