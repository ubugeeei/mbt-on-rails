///|
test "resource app builders expose stable models pages and actions" {
  let schema = note_model()
  let layout = note_layout()
  let pages = note_pages(layout)
  let actions = note_server_actions()

  assert_eq(schema.table, "notes")
  assert_eq(schema.validations.length(), 2)
  assert_eq(layout.name, "application")
  assert_eq(pages.length(), 4)
  assert_eq(pages[0].route_name, "notes_index")
  assert_eq(pages[0].forms.length(), 1)
  assert_eq(pages[0].client_islands.length(), 1)
  assert_eq(actions.length(), 3)
  assert_eq(actions[0].name, "notes.create")
}

///|
test "resource app runtime and main smoke stay runnable" {
  let app = note_app()
  let show_response = @mbor.handle_request(
    app,
    @mbor.request(@mbor.http_get(), "/notes/42", [], [], None, ""),
  )
  let create_response = @mbor.handle_request(
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

  assert_eq(show_response.status, 200)
  assert_true(
    @mbor.render_response_body(show_response.body).contains("notes_show"),
  )
  assert_eq(create_response.status, 200)
  assert_true(
    @mbor.render_response_body(create_response.body).contains("notes.create"),
  )

  print_example(app)
  run_example()
  assert_true(true)
}
