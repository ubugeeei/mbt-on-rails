///|
/// Builds a small Notes app from the public framework APIs.
fn note_app() -> @mbor.MbtOnRailsApp {
  let model = note_model()
  let controller = @mbor.restful_controller("notes", "notes")
  let layout = note_layout()
  @mbor.app(
    "notes example",
    @mbor.default_auth_config(),
    [model],
    [@mbor.migration_from_model("20260323040101", "create_notes", model)],
    [],
    [],
    [],
    [],
    [@mbor.job_queue("default")],
    [],
    [@mbor.cache_store("notes")],
    [controller],
    @mbor.resources(
      "notes",
      controller.name,
      @mbor.default_resource_options("notes", Some("notes")),
    ),
    note_pages(layout),
    note_server_actions(),
    [],
  )
}

///|
/// Prints the most useful outputs from the resource app example.
fn print_example(app : @mbor.MbtOnRailsApp) -> Unit {
  println("Notes Example")
  println("=============")
  println("")
  println("Routes")
  println(app.routes_table())
  println("")
  println("Route Tree")
  println(app.route_tree())
  println("")
  println("SSR Example: /notes/42")
  match app.example_html("/notes/42") {
    Some(html) => println(html)
    None => println("no html")
  }
  println("")
  println("Action Example: POST /_actions/notes.create")
  let action_response = @mbor.handle_request(
    app,
    @mbor.request(
      @mbor.http_post(),
      "/_actions/notes.create",
      [],
      [],
      None,
      "{\"title\":\"hello\"}",
    ),
  )
  println(@mbor.render_response_body(action_response.body))
}
