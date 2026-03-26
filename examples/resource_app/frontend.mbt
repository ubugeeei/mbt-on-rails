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
    )
    .with_layout(layout)
    .with_loader(@mbor.loader_module("load_notes", "notes:index", Some(30), [
      "notes",
    ]))
    .with_action_name("notes.create")
    .with_dynamic_mode(@mbor.dynamic_revalidate(30))
    .with_island(
      @mbor.client_component(
        "NoteCounter",
        "examples/resource_app/views/components/note_counter.mbtv",
        [("count", "12")],
        @mbor.hydrate_visible(),
      ),
    )
    .with_form(
      @mbor.form_binding(
        "note_create",
        "notes.create",
        "POST",
        Some("notes"),
        Some("/notes"),
      ),
    ),
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
    )
    .with_layout(layout)
    .with_loader(@mbor.loader_module("load_note", "notes:show", None, [
      "notes",
    ]))
    .with_action_name("notes.update")
    .with_form(
      @mbor.form_binding(
        "note_update",
        "notes.update",
        "POST",
        Some("note"),
        Some("/notes/[id]"),
      ),
    ),
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
    )
    .with_layout(layout)
    .with_form(
      @mbor.form_binding(
        "note_new",
        "notes.create",
        "POST",
        None,
        Some("/notes"),
      ),
    ),
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
    )
    .with_layout(layout)
    .with_form(
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
