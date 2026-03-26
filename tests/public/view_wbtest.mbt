///|
test "rendered page includes islands forms and route tree data" {
  let layout = layout_module(
    "application",
    mbtv_path("examples/demo_blog/views/layouts/application.mbtv"),
    server_component(
      "ApplicationLayout",
      mbtv_path("examples/demo_blog/views/layouts/application.mbtv"),
      [],
    ),
  )
  let page = page_module(
    "posts_show",
    "/posts/[id]",
    mbtv_path("examples/demo_blog/views/pages/posts/show.mbtv"),
    "Post",
    server_component(
      "PostsShowPage",
      mbtv_path("examples/demo_blog/views/pages/posts/show.mbtv"),
      [],
    ),
  )
  .with_layout(layout)
  .with_loader(loader_module("load_post", "posts:show", Some(60), ["posts"]))
  .with_action_name("posts.update")
  .with_dynamic_mode(dynamic_revalidate(60))
  .with_island(
    client_component(
      "LikeButton",
      mbtv_path("examples/demo_blog/views/components/like_button.mbtv"),
      [("kind", "heart")],
      hydrate_visible(),
    ),
  )
  .with_form(
    form_binding(
      "post_update",
      "posts.update",
      "POST",
      Some("post"),
      Some("/posts/[id]"),
    ),
  )
  let actions = [
    server_action(
      "posts.update",
      "/_actions/posts.update",
      [("id", "String"), ("title", "String")],
      "PostPayload",
      true,
    ),
  ]

  let rendered = render_page(
    page,
    [("id", "42")],
    [("title", "MoonBit")],
    actions,
  )

  assert_true(rendered.html.contains("data-mbor-page=\"posts_show\""))
  assert_true(rendered.html.contains("client:visible"))
  assert_true(rendered.html.contains("LikeButton"))
  assert_true(
    rendered.data_json.contains("\"dynamic_mode\": \"revalidate:60\""),
  )
  assert_true(render_form_manifest(page.forms).contains("\"method\": \"POST\""))
  assert_true(
    render_route_tree([page]).contains("\"segments\": [\"posts\", \"[id]\"]"),
  )
}

///|
test "scaffold and demo app expose richer rails style surfaces" {
  let scaffold = scaffold_resource("comments", [
    scaffold_field("body", text_column("body")),
    scaffold_field("post_id", references_column("post_id", "posts")),
  ])

  assert_eq(scaffold.routes.length(), 8)
  assert_eq(scaffold.server_actions.length(), 2)
  assert_true(
    scaffold.artifacts[0].path.contains(
      "examples/scaffold/views/pages/comments/index.mbtv",
    ),
  )

  let demo = demo_blog_app()
  let page_response = handle_request(
    demo,
    request(http_get(), "/posts/42", [], [], None, ""),
  )
  assert_eq(page_response.status, 200)
  assert_true(render_response_body(page_response.body).contains("posts_show"))

  let action_response = handle_request(
    demo,
    request(
      http_post(),
      "/_actions/posts.create",
      [],
      [],
      None,
      "{\"title\":\"hello\"}",
    ),
  )
  assert_eq(action_response.status, 200)
  assert_true(
    render_response_body(action_response.body).contains("posts.create"),
  )
  assert_true(demo.router_manifest().contains("\"route_name\": \"posts_show\""))
  assert_true(demo.schema_statements().length() >= 3)
}
