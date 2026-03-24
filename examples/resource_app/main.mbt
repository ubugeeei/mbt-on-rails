///|
/// Builds the `Note` model used by the resource app example.
fn note_model() -> @mbor.ModelSchema {
  @mbor.with_validation(
    @mbor.with_validation(
      @mbor.model(
        "Note",
        "notes",
        [
          @mbor.string_column("title"),
          @mbor.text_column("body"),
          @mbor.indexed(@mbor.string_column("slug")),
        ],
        true,
        false,
      ),
      @mbor.validates_presence("title"),
    ),
    @mbor.validates_length_min("body", 10),
  )
}

///|
/// Builds the layout shared by the example pages.
fn note_layout() -> @mbor.LayoutModule {
  @mbor.layout_module(
    "application",
    "examples/resource_app/views/layouts/application.mbtv",
    @mbor.server_component(
      "NoteLayout",
      "examples/resource_app/views/layouts/application.mbtv",
      [],
    ),
  )
}

///|
/// Builds the page modules used by the example Notes app.
fn note_pages(layout : @mbor.LayoutModule) -> Array[@mbor.PageModule] {
  [
    @mbor.with_form(
      @mbor.with_island(
        @mbor.with_dynamic_mode(
          @mbor.with_action_name(
            @mbor.with_loader(
              @mbor.with_layout(
                @mbor.page_module(
                  "notes_index",
                  "/notes",
                  "examples/resource_app/views/pages/notes/index.mbtv",
                  "Notes",
                  @mbor.server_component(
                    "NotesIndexPage",
                    "examples/resource_app/views/pages/notes/index.mbtv",
                    [],
                  ),
                ),
                layout,
              ),
              @mbor.loader_module("load_notes", "notes:index", Some(30), [
                "notes",
              ]),
            ),
            "notes.create",
          ),
          @mbor.dynamic_revalidate(30),
        ),
        @mbor.client_component(
          "NoteCounter",
          "examples/resource_app/views/components/note_counter.mbtv",
          [("count", "12")],
          @mbor.hydrate_visible(),
        ),
      ),
      @mbor.form_binding(
        "note_create",
        "notes.create",
        "POST",
        Some("notes"),
        Some("/notes"),
      ),
    ),
    @mbor.with_form(
      @mbor.with_action_name(
        @mbor.with_loader(
          @mbor.with_layout(
            @mbor.page_module(
              "notes_show",
              "/notes/[id]",
              "examples/resource_app/views/pages/notes/show.mbtv",
              "Note",
              @mbor.server_component(
                "NotesShowPage",
                "examples/resource_app/views/pages/notes/show.mbtv",
                [],
              ),
            ),
            layout,
          ),
          @mbor.loader_module("load_note", "notes:show", None, ["notes"]),
        ),
        "notes.update",
      ),
      @mbor.form_binding(
        "note_update",
        "notes.update",
        "POST",
        Some("note"),
        Some("/notes/[id]"),
      ),
    ),
    @mbor.with_form(
      @mbor.with_layout(
        @mbor.page_module(
          "notes_new",
          "/notes/new",
          "examples/resource_app/views/pages/notes/new.mbtv",
          "New Note",
          @mbor.server_component(
            "NotesNewPage",
            "examples/resource_app/views/pages/notes/new.mbtv",
            [],
          ),
        ),
        layout,
      ),
      @mbor.form_binding(
        "note_new",
        "notes.create",
        "POST",
        None,
        Some("/notes"),
      ),
    ),
    @mbor.with_form(
      @mbor.with_layout(
        @mbor.page_module(
          "notes_edit",
          "/notes/[id]/edit",
          "examples/resource_app/views/pages/notes/edit.mbtv",
          "Edit Note",
          @mbor.server_component(
            "NotesEditPage",
            "examples/resource_app/views/pages/notes/edit.mbtv",
            [],
          ),
        ),
        layout,
      ),
      @mbor.form_binding(
        "note_edit",
        "notes.update",
        "POST",
        None,
        Some("/notes/[id]"),
      ),
    ),
  ]
}

///|
/// Builds the server action manifest used by the example app.
fn note_server_actions() -> Array[@mbor.ServerAction] {
  [
    @mbor.server_action(
      "notes.create",
      "/_actions/notes.create",
      [("title", "String"), ("body", "String"), ("slug", "String")],
      "NotePayload",
      true,
    ),
    @mbor.server_action(
      "notes.update",
      "/_actions/notes.update",
      [
        ("id", "String"),
        ("title", "String"),
        ("body", "String"),
        ("slug", "String"),
      ],
      "NotePayload",
      true,
    ),
    @mbor.server_action(
      "notes.destroy",
      "/_actions/notes.destroy",
      [("id", "String")],
      "Unit",
      true,
    ),
  ]
}

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

///|
fn main {
  print_example(note_app())
}
