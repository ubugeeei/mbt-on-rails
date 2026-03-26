///|
/// Builds the mailers configured by the demo app.
pub fn demo_mailers() -> Array[@mailer.MailerDefinition] {
  [demo_session_mailer()]
}

///|
/// Builds the job queues shown by the demo app.
pub fn demo_job_queues() -> Array[@job.JobQueue] {
  let reindex_job = @job.job(
    name="posts.reindex",
    queue="default",
    argument_types=[("resource", "String"), ("id", "String")],
    retry_limit=3,
    unique_key=Some("posts:search"),
  )
  .retry_on("TimeoutError", attempts=4, wait=@job.fixed_wait(seconds=5))
  .discard_on("DeserializationError")
  let publish_job = @job.job(
    name="posts.publish",
    queue="default",
    argument_types=[("id", "String")],
    retry_limit=2,
    unique_key=None,
  ).retry_on(
    "RemoteApiError",
    attempts=3,
    wait=@job.polynomially_longer(),
  )
  let default_queue = @job.enqueue_at(
    @job.enqueue_now(
      @job.job_queue(name="default"),
      reindex_job,
      [("resource", "posts"), ("id", "42")],
    ),
    publish_job,
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
      @mailer.enqueue_delivery(@job.job_queue(name="mailers"), delivery, None)
    None => @job.job_queue(name="mailers")
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
  @mailer.mailer(
    name="SessionMailer",
    from="noreply@mbt-on-rails.dev",
    layout_name=Some("mailer"),
    templates=[
      @mailer.mail_template(
        action_name="welcome",
        subject="Welcome to mbt on rails",
        html_path=view_mailer_welcome_html(),
        text_path=Some("examples/demo_blog/views/mailer/welcome.text"),
      ),
      @mailer.mail_template(
        action_name="password_reset",
        subject="Reset your password",
        html_path=view_mailer_password_reset_html(),
        text_path=Some("examples/demo_blog/views/mailer/password_reset.text"),
      ),
    ],
  )
}
