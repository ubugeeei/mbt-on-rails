///|
/// Builds a small Notes app from the public framework APIs.
fn note_app() -> @mbor.MbtOnRailsApp {
  let model = note_model()
  let controller = @mbor.restful_controller("notes", "notes")
  let layout = note_layout()
  @mbor.app_named("notes example")
  .with_model(model)
  .with_migration(
    @mbor.migration_from_model("20260323040101", "create_notes", model),
  )
  .with_job_queue(@mbor.job_queue("default"))
  .with_cache(@mbor.cache_store("notes"))
  .with_controller(controller)
  .with_routes(
    @mbor.resources(
      "notes",
      controller.name,
      @mbor.default_resource_options("notes", Some("notes")),
    ),
  )
  .with_pages(note_pages(layout))
  .with_server_actions(note_server_actions())
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
  match app.example_html(notes_show_path(notes_show_route_params(id="42"))) {
    Some(html) => println(html)
    None => println("no html")
  }
  println("")
  println("Action Example: POST /_actions/notes.create")
  let action_response = @mbor.handle_request(
    app,
    @mbor.request(
      verb=@mbor.http_post(),
      path="/_actions/notes.create",
      query=[],
      form=[],
      session_id=None,
      body="{\"title\":\"hello\"}",
    ),
  )
  println(@mbor.render_response_body(action_response.body))
}
