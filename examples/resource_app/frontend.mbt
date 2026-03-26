///|
/// Builds the layout shared by the example pages.
fn note_layout() -> @mbor.LayoutModule {
  @mbor.layout_module(
    name="application",
    file_path=view_layouts_application(),
    component=@mbor.server_component(
      name="NoteLayout",
      source_path=view_layouts_application(),
      props=[],
    ),
  )
}

///|
/// Builds the page modules used by the example Notes app.
fn note_pages(layout : @mbor.LayoutModule) -> Array[@mbor.PageModule] {
  [
    @mbor.page_module(
      route_name="notes_index",
      route_path="/notes",
      file_path=view_pages_notes_index(),
      title="Notes",
      component=@mbor.server_component(
        name="NotesIndexPage",
        source_path=view_pages_notes_index(),
        props=[],
      ),
    )
    .with_layout(layout)
    .with_loader(
      @mbor.loader_module(
        name="load_notes",
        cache_key="notes:index",
        revalidate_seconds=Some(30),
        depends_on=["notes"],
      ),
    )
    .with_action_name("notes.create")
    .with_dynamic_mode(@mbor.dynamic_revalidate(30))
    .with_island(
      @mbor.client_component(
        name="NoteCounter",
        source_path=view_components_note_counter(),
        props=[("count", "12")],
        hydration=@mbor.hydrate_visible(),
      ),
    )
    .with_form(
      @mbor.form_binding(
        name="note_create",
        action_name="notes.create",
        verb="POST",
        optimistic_key=Some("notes"),
        redirect_to=Some("/notes"),
      ),
    ),
    @mbor.page_module(
      route_name="notes_show",
      route_path="/notes/[id]",
      file_path=view_pages_notes_show(),
      title="Note",
      component=@mbor.server_component(
        name="NotesShowPage",
        source_path=view_pages_notes_show(),
        props=[],
      ),
    )
    .with_layout(layout)
    .with_loader(
      @mbor.loader_module(
        name="load_note",
        cache_key="notes:show",
        revalidate_seconds=None,
        depends_on=["notes"],
      ),
    )
    .with_action_name("notes.update")
    .with_form(
      @mbor.form_binding(
        name="note_update",
        action_name="notes.update",
        verb="POST",
        optimistic_key=Some("note"),
        redirect_to=Some("/notes/[id]"),
      ),
    ),
    @mbor.page_module(
      route_name="notes_new",
      route_path="/notes/new",
      file_path=view_pages_notes_new(),
      title="New Note",
      component=@mbor.server_component(
        name="NotesNewPage",
        source_path=view_pages_notes_new(),
        props=[],
      ),
    )
    .with_layout(layout)
    .with_form(
      @mbor.form_binding(
        name="note_new",
        action_name="notes.create",
        verb="POST",
        optimistic_key=None,
        redirect_to=Some("/notes"),
      ),
    ),
    @mbor.page_module(
      route_name="notes_edit",
      route_path="/notes/[id]/edit",
      file_path=view_pages_notes_edit(),
      title="Edit Note",
      component=@mbor.server_component(
        name="NotesEditPage",
        source_path=view_pages_notes_edit(),
        props=[],
      ),
    )
    .with_layout(layout)
    .with_form(
      @mbor.form_binding(
        name="note_edit",
        action_name="notes.update",
        verb="POST",
        optimistic_key=None,
        redirect_to=Some("/notes/[id]"),
      ),
    ),
  ]
}

///|
/// Builds the server action manifest used by the example app.
fn note_server_actions() -> Array[@mbor.ServerAction] {
  [
    @mbor.server_action(
      name="notes.create",
      route="/_actions/notes.create",
      input_fields=[("title", "String"), ("body", "String"), ("slug", "String")],
      output_type="NotePayload",
      csrf_protected=true,
    ),
    @mbor.server_action(
      name="notes.update",
      route="/_actions/notes.update",
      input_fields=[
        ("id", "String"),
        ("title", "String"),
        ("body", "String"),
        ("slug", "String"),
      ],
      output_type="NotePayload",
      csrf_protected=true,
    ),
    @mbor.server_action(
      name="notes.destroy",
      route="/_actions/notes.destroy",
      input_fields=[("id", "String")],
      output_type="Unit",
      csrf_protected=true,
    ),
  ]
}
