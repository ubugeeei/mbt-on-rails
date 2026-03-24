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
/// Prints an Active Job plus Action Mailer example.
fn print_job_and_mailer_example() -> Unit {
  let announcement_mailer = @mbor.mailer(
    "AnnouncementMailer",
    "noreply@example.com",
    Some("mailer"),
    [
      @mbor.mail_template(
        "launch",
        "Launch update",
        "examples/demo_blog/views/mailer/welcome.html.mbtv",
        Some("examples/demo_blog/views/mailer/welcome.text"),
      ),
    ],
  )
  match
    @mbor.compose_mail(announcement_mailer, "launch", ["team@example.com"], [
      ("headline", "mbt on rails ships more Rails surfaces"),
    ]) {
    Some(delivery) => {
      let queue = @mbor.enqueue_delivery(
        @mbor.job_queue("mailers"),
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
fn main {
  println("Rails Ops Example")
  println("=================")
  println("")
  print_params_example()
  print_job_and_mailer_example()
  print_cache_example()
}
