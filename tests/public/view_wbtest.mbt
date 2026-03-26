///|
test "rendered page includes islands forms and route tree data" {
  let layout = layout_module(
    name="application",
    file_path=mbtv_path("examples/demo_blog/views/layouts/application.mbtv"),
    component=server_component(
      name="ApplicationLayout",
      source_path=mbtv_path("examples/demo_blog/views/layouts/application.mbtv"),
      props=[],
    ),
  )
  let hero_partial = server_component(
    name="PostHero",
    source_path=mbtv_path("examples/demo_blog/views/components/post_hero.mbtv"),
    props=[("title", "MoonBit on Rails")],
  ).with_contract(
    server_contract(
      props=[
        prop_contract(
          name="title",
          type_name="String",
          required=true,
          description="Hero title",
        ),
      ],
      async_only=false,
    ),
  )
  let binding = form_binding(
    name="post_update",
    action_name="posts.update",
    verb="POST",
    optimistic_key=Some("post"),
    redirect_to=Some("/posts/[id]"),
  )
  let page = page_module(
      route_name="posts_show",
      route_path="/posts/[id]",
      file_path=mbtv_path("examples/demo_blog/views/pages/posts/show.mbtv"),
      title="Post",
      component=server_component(
          name="PostsShowPage",
          source_path=mbtv_path(
            "examples/demo_blog/views/pages/posts/show.mbtv",
          ),
          props=[],
        )
        .with_partial(partial(local_name="PostHero", component=hero_partial))
        .with_child(
          render_partial(name="PostHero", locals=[("title", "MoonBit on Rails")]),
        ),
    )
    .with_layout(layout)
    .with_loader(
      loader_module(
        name="load_post",
        cache_key="posts:show",
        revalidate_seconds=Some(60),
        depends_on=["posts"],
      ),
    )
    .with_action_name("posts.update")
    .with_dynamic_mode(dynamic_revalidate(60))
    .with_island(
      client_component(
        name="LikeButton",
        source_path=mbtv_path(
          "examples/demo_blog/views/components/like_button.mbtv",
        ),
        props=[("kind", "heart")],
        hydration=hydrate_visible(),
      ),
    )
    .with_form_builder(
      form_builder(
        name="post_update_form",
        binding~,
        fields=[
          text_field(
            name="title",
            label="Title",
            placeholder=Some("MoonBit on Rails"),
          ),
          textarea_field(
            name="body",
            label="Body",
            help_text=Some("Rendered through typed form metadata"),
          ),
        ],
        submit_label="Save post",
        description=Some("Edit form for one post"),
      ),
    )
  let actions = [
    server_action(
      name="posts.update",
      route="/_actions/posts.update",
      input_fields=[("id", "String"), ("title", "String")],
      output_type="PostPayload",
      csrf_protected=true,
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
  assert_true(rendered.html.contains("data-mbor-import=\"PostHero\""))
  assert_true(rendered.html.contains("id=\"mbor-form-builders\""))
  assert_true(
    rendered.data_json.contains("\"dynamic_mode\": \"revalidate:60\""),
  )
  assert_true(render_form_manifest(page.forms).contains("\"method\": \"POST\""))
  assert_true(
    render_form_builder_manifest(page.form_builders).contains(
      "\"submit_label\": \"Save post\"",
    ),
  )
  assert_true(
    render_form_builder_manifest(page.form_builders).contains(
      "\"kind\": \"textarea\"",
    ),
  )
  assert_eq(validate_page_tree(page), [])
  assert_true(
    rendered.component_manifest_json.contains("\"local_name\": \"PostHero\""),
  )
  assert_true(
    rendered.form_builder_manifest_json.contains(
      "\"binding_name\": \"post_update\"",
    ),
  )
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
  assert_eq(scaffold.pages.length(), 4)
  assert_eq(scaffold.server_actions.length(), 3)
  assert_eq(scaffold.controller.actions[3].allowed_params, ["body", "post_id"])
  assert_eq(scaffold.pages[0].forms.length(), 1)
  assert_eq(scaffold.pages[0].client_islands.length(), 1)
  assert_eq(scaffold.pages[1].forms.length(), 2)
  assert_eq(scaffold.server_actions[0].input_fields[0].1, "String")
  assert_true(
    scaffold.artifacts[0].path.contains(
      "examples/scaffold/views/pages/comments/index.mbtv",
    ),
  )
  assert_true(
    scaffold.artifacts[5].path.contains(
      "examples/scaffold/views/components/comment_counter.mbtv",
    ),
  )

  let demo = demo_blog_app()
  let page_response = handle_request(
    demo,
    request(
      verb=http_get(),
      path="/posts/42",
      query=[],
      form=[],
      session_id=None,
      body="",
    ),
  )
  assert_eq(page_response.status, 200)
  assert_true(render_response_body(page_response.body).contains("posts_show"))

  let action_response = handle_request(
    demo,
    request(
      verb=http_post(),
      path="/_actions/posts.create",
      query=[],
      form=[],
      session_id=None,
      body="{\"title\":\"hello\"}",
    ),
  )
  assert_eq(action_response.status, 200)
  assert_true(
    render_response_body(action_response.body).contains("posts.create"),
  )
  assert_true(demo.router_manifest().contains("\"route_name\": \"posts_show\""))
  assert_true(demo.schema_statements().length() >= 3)
  assert_true(
    render_response_body(page_response.body).contains("mbor-form-builders"),
  )
}
