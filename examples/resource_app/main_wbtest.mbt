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
    @mbor.request(
      verb=@mbor.http_get(),
      path="/notes/42",
      query=[],
      form=[],
      session_id=None,
      body="",
    ),
  )
  let create_response = @mbor.handle_request(
    app,
    @mbor.append_request_header(
      @mbor.request(
        verb=@mbor.http_post(),
        path="/_actions/notes.create",
        query=[],
        form=[],
        session_id=None,
        body="{\"title\":\"hello\"}",
      ),
      "x-csrf-token",
      "token",
    ),
  )
  let new_guest_response = @mbor.handle_request(
    app,
    @mbor.request(
      verb=@mbor.http_get(),
      path="/notes/new",
      query=[],
      form=[],
      session_id=None,
      body="",
    ),
  )
  let new_signed_in_response = @mbor.handle_request(
    app,
    @mbor.request(
      verb=@mbor.http_get(),
      path="/notes/new",
      query=[],
      form=[],
      session_id=Some("sess_1"),
      body="",
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
  assert_eq(new_guest_response.status, 401)
  assert_eq(new_signed_in_response.status, 200)

  print_example(app)
  run_example()
  assert_true(true)
}
