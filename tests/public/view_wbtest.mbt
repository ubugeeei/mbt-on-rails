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
  assert_true(validate_page_tree(page) == [])
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
test "action view style helpers render concise typed html fragments" {
  let navigation = content_tag(
    name="nav",
    content=safe_join(
      [
        link_to(label="Posts", href="/posts", attrs=[
          (
            "class",
            class_names([
              ("nav-link", true),
              ("is-active", true),
              ("is-hidden", false),
            ]),
          ),
        ]),
        button_to(
          label="Delete",
          action="/posts/42",
          http_method="delete",
          attrs=[("class", "danger")],
          form_attrs=[("class", "inline")],
        ),
        image_tag(src="/assets/logo.svg", alt="MoonBit on Rails", attrs=[
          ("loading", "lazy"),
        ]),
      ],
      separator="\n",
    ),
    attrs=[
      (
        "id",
        dom_id(record_name="posts", record_id=Some("42"), prefix=Some("admin")),
      ),
    ],
    escape=false,
  )

  assert_true(navigation.contains("<nav id=\"admin_post_42\">"))
  assert_true(
    navigation.contains(
      "<a href=\"/posts\" class=\"nav-link is-active\">Posts</a>",
    ),
  )
  assert_true(
    navigation.contains(
      "<form action=\"/posts/42\" method=\"post\" class=\"inline\">",
    ),
  )
  assert_true(
    navigation.contains(
      "<input type=\"hidden\" name=\"_method\" value=\"delete\">",
    ),
  )
  assert_true(
    navigation.contains(
      "<button type=\"submit\" class=\"danger\">Delete</button>",
    ),
  )
  assert_true(
    navigation.contains(
      "<img src=\"/assets/logo.svg\" alt=\"MoonBit on Rails\" loading=\"lazy\">",
    ),
  )
  assert_eq(
    tag(name="br", attrs=[("class", "spacer")]),
    "<br class=\"spacer\">",
  )
  assert_eq(
    tag(name="img src=x", attrs=[
      ("data-id", "42"),
      ("aria-label", "Logo"),
      ("bad name", "forged"),
    ]),
    "<span data-id=\"42\" aria-label=\"Logo\">",
  )
  assert_eq(
    content_tag(name="script>alert", content="safe", attrs=[
      ("class", "ok"),
      ("on click", "forged"),
    ]),
    "<span class=\"ok\">safe</span>",
  )
  assert_eq(pluralize(1, "comment"), "1 comment")
  assert_eq(pluralize(2, "category"), "2 categories")
}

///|
test "application json scripts remain parseable and block script breakouts" {
  let page = page_module(
    route_name="security_probe",
    route_path="/security",
    file_path=mbtv_path("examples/security/views/pages/probe.mbtv"),
    title="Security",
    component=server_component(
      name="SecurityProbePage",
      source_path=mbtv_path("examples/security/views/pages/probe.mbtv"),
      props=[],
    ),
  )
  let injected = "</script><script>alert(1)</script>&"
  let rendered = render_page(page, [("payload", injected)], [], [])

  assert_true(
    rendered.data_json.contains(
      "\"payload\": \"</script><script>alert(1)</script>&\"",
    ),
  )
  assert_false(rendered.html.contains("&quot;payload&quot;"))
  assert_true(
    rendered.html.contains(
      "\"payload\": \"\\u003c/script\\u003e\\u003cscript\\u003ealert(1)\\u003c/script\\u003e\\u0026\"",
    ),
  )
  assert_false(rendered.html.contains("</script><script>alert(1)</script>"))
}

///|
test "component fallback html is escaped in placeholders and manifests" {
  let fallback = "<img src=x onerror=alert(1)></template><script>alert(1)</script>"
  let page = page_module(
    route_name="fallback_probe",
    route_path="/fallback",
    file_path=mbtv_path("examples/security/views/pages/fallback.mbtv"),
    title="Fallback",
    component=server_component(
        name="FallbackProbePage",
        source_path=mbtv_path("examples/security/views/pages/fallback.mbtv"),
        props=[],
      )
      .with_fallback(fallback)
      .with_child(
        suspense_boundary(name="AsyncPanel", fallback_html=fallback, children=[]),
      ),
  )
  let rendered = render_page(page, [], [], [])

  assert_true(rendered.html.contains("data-mbor-fallback"))
  assert_true(rendered.html.contains("&lt;img src=x onerror=alert(1)&gt;"))
  assert_true(rendered.html.contains("&lt;/template&gt;"))
  assert_false(rendered.html.contains("<img src=x"))
  assert_false(rendered.html.contains("</template><script>alert(1)</script>"))
  assert_true(
    rendered.component_manifest_json.contains(
      "&lt;img src=x onerror=alert(1)&gt;",
    ),
  )
  assert_false(rendered.component_manifest_json.contains("<script>alert"))
}

///|
test "view helpers and page assets neutralize dangerous url schemes" {
  assert_eq(
    link_to(label="Docs", href="https://example.com/docs"),
    "<a href=\"https://example.com/docs\">Docs</a>",
  )
  assert_eq(
    link_to(label="Email", href="mailto:hello@example.com"),
    "<a href=\"mailto:hello@example.com\">Email</a>",
  )
  assert_eq(
    link_to(label="Bad", href=" java\nscript:alert(1)", attrs=[
      ("onclick", "alert(1)"),
    ]),
    "<a href=\"#\">Bad</a>",
  )
  assert_eq(
    button_to(label="Go", action="javascript:alert(1)"),
    "<form action=\"#\" method=\"post\"><button type=\"submit\">Go</button></form>",
  )
  assert_eq(
    image_tag(src="data:text/html,<script>alert(1)</script>", alt="Logo", attrs=[
      ("onerror", "alert(1)"),
    ]),
    "<img src=\"about:blank\" alt=\"Logo\">",
  )
  assert_true(
    image_tag(src="data:image/png;base64,AAAA", alt="Pixel").contains(
      "src=\"data:image/png;base64,AAAA\"",
    ),
  )

  let page = page_module(
    route_name="asset_probe",
    route_path="/assets",
    file_path=mbtv_path("examples/security/views/pages/assets.mbtv"),
    title="Assets",
    component=server_component(
      name="AssetProbePage",
      source_path=mbtv_path("examples/security/views/pages/assets.mbtv"),
      props=[],
    ),
  ).with_assets(
    asset_manifest(
      style_urls=[
        "/assets/app.css", "javascript:alert(1)", "data:text/css,body{}",
      ],
      script_urls=[
        "https://cdn.example.test/app.js", "data:text/javascript,alert(1)", "java\nscript:alert(1)",
      ],
    ),
  )
  let rendered = render_page(page, [], [], [])

  assert_true(rendered.html.contains("href=\"/assets/app.css\""))
  assert_true(rendered.html.contains("src=\"https://cdn.example.test/app.js\""))
  assert_false(rendered.html.contains("javascript:alert"))
  assert_false(rendered.html.contains("data:text"))
}

///|
test "template validation ignores commented and string component imports" {
  let errors = validate_template_component_imports(
    "app/views/posts/show.mbtv",
    "<script setup>\n" +
    "// component LikeButton,\n" +
    "let docs = \"component Card\"\n" +
    "component SaveButton,\n" +
    "</script>\n" +
    "<template><LikeButton /><SaveButton /></template>\n",
  )

  assert_true(
    errors.contains(
      "app/views/posts/show.mbtv: missing component import for <LikeButton>",
    ),
  )
  assert_false(
    errors.contains(
      "app/views/posts/show.mbtv: missing component import for <SaveButton>",
    ),
  )
  assert_false(errors.contains("unused component import Card"))
}

///|
test "vapor moon compatibility helpers expose richer component metadata" {
  let root_ref : TemplateRef[String] = use_template_ref("root")
  let island = client_component(
    name="CounterPanel",
    source_path=mbtv_path(
      "examples/demo_blog/views/components/counter_panel.mbtv",
    ),
    props=[("title", "Dashboard")],
    hydration=hydrate_load(),
  ).with_contract(
    client_contract(
      props=[
        prop_contract(
          name="title",
          type_name="String",
          required=true,
          description="Panel heading",
        ),
        prop_contract(
          name="count",
          type_name="Int",
          required=true,
          description="Visible count",
          default_value=Some("0"),
        ),
      ],
      props_binding=Some("props"),
      emits_binding=Some("emit"),
      slots_binding=Some("slots"),
      emits=[
        emit_contract(
          name="save",
          signature="String",
          description=Some("Persist one value"),
        ),
      ],
      slots=[
        slot_contract(
          name="footer",
          signature="String",
          description=Some("Footer slot"),
        ),
      ],
      template_refs=[
        template_ref_contract(ref_name="root", binding_name=Some("root_ref")),
      ],
      transport="json",
    ),
  )
  let page = page_module(
    route_name="dashboard",
    route_path="/dashboard",
    file_path=mbtv_path("examples/demo_blog/views/pages/home.mbtv"),
    title="Dashboard",
    component=server_component(
      name="DashboardPage",
      source_path=mbtv_path("examples/demo_blog/views/pages/home.mbtv"),
      props=[],
    ),
  ).with_island(island)

  let manifest = render_component_manifest(page)
  let rendered = render_page(page, [], [], [])

  assert_eq(root_ref.name(), "root")
  assert_true(manifest.contains("\"scope_id\": \"vm-"))
  assert_true(
    manifest.contains("\"client_module_path\": \"/_vapor_moon/CounterPanel-"),
  )
  assert_true(manifest.contains("\"default_value\": \"0\""))
  assert_true(manifest.contains("\"emits_binding\": \"emit\""))
  assert_true(manifest.contains("\"slots_binding\": \"slots\""))
  assert_true(manifest.contains("\"signature\": \"String\""))
  assert_true(manifest.contains("\"ref_name\": \"root\""))
  assert_true(rendered.html.contains("data-mbor-scope=\"vm-"))
  assert_true(
    rendered.html.contains(
      "data-mbor-client-module=\"/_vapor_moon/CounterPanel-",
    ),
  )
  assert_true(
    client_module_path("CounterPanel").has_prefix("/_vapor_moon/CounterPanel-"),
  )
  assert_true(make_scope_id("CounterPanel").has_prefix("vm-"))
  assert_eq(
    props_to_json([("count", "1"), ("ready", "true")]),
    "{\"count\": 1, \"ready\": true}",
  )
  assert_true(
    scope_css(".panel { color: red; }", make_scope_id("CounterPanel")).contains(
      "[data-vm-scope=\"",
    ),
  )
  assert_eq(show_style(false, "color: red;"), "color: red; display: none;")
  assert_eq(merge_class_names(["panel", "", "island"]), "panel island")
  assert_eq(
    merge_styles(["color: red", "display: block;"]),
    "color: red; display: block;",
  )
  assert_true(use_id("CounterPanel", 2).contains("-id-2"))
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
  assert_true(
    scaffold.controller.actions[3].allowed_params == ["body", "post_id"],
  )
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

  let valid_action_token = sign_cookie_value(
    "server_action:posts.create",
    "sess_1",
    demo.auth.secret_key_base,
  )
  let wrong_action_token = sign_cookie_value(
    "server_action:posts.update",
    "sess_1",
    demo.auth.secret_key_base,
  )
  let action_request = append_request_header(
    request(
      verb=http_post(),
      path="/_actions/posts.create",
      query=[],
      form=[("title", "hello"), ("slug", "hello"), ("body", "body")],
      session_id=Some("sess_1"),
      body="{\"title\":\"hello\"}",
    ),
    "x-csrf-token",
    valid_action_token,
  )
  let action_response = handle_request(demo, action_request)
  let arbitrary_csrf_response = handle_request(
    demo,
    append_request_header(
      request(
        verb=http_post(),
        path="/_actions/posts.create",
        query=[],
        form=[("title", "hello"), ("slug", "hello"), ("body", "body")],
        session_id=Some("sess_1"),
        body="{\"title\":\"hello\"}",
      ),
      "x-csrf-token",
      "token",
    ),
  )
  let wrong_action_csrf_response = handle_request(
    demo,
    append_request_header(
      request(
        verb=http_post(),
        path="/_actions/posts.create",
        query=[],
        form=[("title", "hello"), ("slug", "hello"), ("body", "body")],
        session_id=Some("sess_1"),
        body="{\"title\":\"hello\"}",
      ),
      "x-csrf-token",
      wrong_action_token,
    ),
  )
  let missing_session_response = handle_request(
    demo,
    append_request_header(
      request(
        verb=http_post(),
        path="/_actions/posts.create",
        query=[],
        form=[("title", "hello"), ("slug", "hello"), ("body", "body")],
        session_id=None,
        body="{\"title\":\"hello\"}",
      ),
      "x-csrf-token",
      valid_action_token,
    ),
  )
  let empty_form_response = handle_request(
    demo,
    append_request_header(
      request(
        verb=http_post(),
        path="/_actions/posts.create",
        query=[],
        form=[],
        session_id=Some("sess_1"),
        body="{\"title\":\"hello\"}",
      ),
      "x-csrf-token",
      valid_action_token,
    ),
  )
  let empty_form_no_input_response = handle_request(
    demo,
    append_request_header(
      request(
        verb=http_post(),
        path="/_actions/sessions.destroy",
        query=[],
        form=[],
        session_id=Some("sess_1"),
        body="",
      ),
      "x-csrf-token",
      sign_cookie_value(
        "server_action:sessions.destroy",
        "sess_1",
        demo.auth.secret_key_base,
      ),
    ),
  )
  let missing_csrf_response = handle_request(
    demo,
    request(
      verb=http_post(),
      path="/_actions/posts.create",
      query=[],
      form=[("title", "hello"), ("slug", "hello"), ("body", "body")],
      session_id=Some("sess_1"),
      body="{\"title\":\"hello\"}",
    ),
  )
  let wrong_method_response = handle_request(
    demo,
    request(
      verb=http_get(),
      path="/_actions/posts.create",
      query=[],
      form=[],
      session_id=None,
      body="",
    ),
  )
  let missing_form_response = handle_request(
    demo,
    append_request_header(
      request(
        verb=http_post(),
        path="/_actions/posts.create",
        query=[],
        form=[("title", "hello")],
        session_id=Some("sess_1"),
        body="",
      ),
      "x-csrf-token",
      valid_action_token,
    ),
  )
  let signed_in_sign_in_response = handle_request(
    demo,
    request(
      verb=http_get(),
      path="/sign-in",
      query=[],
      form=[],
      session_id=Some("sess_1"),
      body="",
    ),
  )
  let sign_out_guest_response = handle_request(
    demo,
    request(
      verb=http_delete(),
      path="/sign-out",
      query=[],
      form=[],
      session_id=None,
      body="",
    ),
  )
  assert_eq(action_response.status, 200)
  assert_true(
    render_response_body(action_response.body).contains("posts.create"),
  )
  assert_eq(arbitrary_csrf_response.status, 422)
  assert_true(
    render_response_body(arbitrary_csrf_response.body).contains(
      "invalid_csrf_token",
    ),
  )
  assert_eq(wrong_action_csrf_response.status, 422)
  assert_true(
    render_response_body(wrong_action_csrf_response.body).contains(
      "invalid_csrf_token",
    ),
  )
  assert_eq(missing_session_response.status, 422)
  assert_true(
    render_response_body(missing_session_response.body).contains(
      "invalid_csrf_token",
    ),
  )
  assert_eq(missing_csrf_response.status, 422)
  assert_true(
    render_response_body(missing_csrf_response.body).contains(
      "invalid_csrf_token",
    ),
  )
  assert_eq(wrong_method_response.status, 404)
  assert_eq(missing_form_response.status, 422)
  assert_true(
    render_response_body(missing_form_response.body).contains(
      "missing action input",
    ),
  )
  assert_eq(empty_form_response.status, 422)
  assert_true(
    render_response_body(empty_form_response.body).contains(
      "missing action input",
    ),
  )
  assert_eq(empty_form_no_input_response.status, 200)
  assert_eq(signed_in_sign_in_response.status, 403)
  assert_eq(sign_out_guest_response.status, 401)
  assert_true(demo.router_manifest().contains("\"route_name\": \"posts_show\""))
  assert_true(demo.schema_statements().length() >= 3)
  assert_true(
    render_response_body(page_response.body).contains("mbor-form-builders"),
  )
}

///|
test "server actions do not shadow normal get routes with the same path" {
  let demo = app_named("collision")
    .with_route(
      route(
        name="profile",
        verb=http_get(),
        path="/profile",
        controller="ProfilesController",
        action="show",
        page_name=None,
      ),
    )
    .with_server_action(
      server_action(
        name="profiles.update",
        route="/profile",
        input_fields=[],
        output_type="ProfilePayload",
        csrf_protected=false,
      ),
    )

  let page_response = handle_request(
    demo,
    request(
      verb=http_get(),
      path="/profile",
      query=[],
      form=[],
      session_id=None,
      body="",
    ),
  )
  let action_response = handle_request(
    demo,
    request(
      verb=http_post(),
      path="/profile",
      query=[],
      form=[],
      session_id=None,
      body="",
    ),
  )

  assert_eq(page_response.status, 200)
  assert_true(
    render_response_body(page_response.body).contains(
      "handled ProfilesController#show",
    ),
  )
  assert_eq(action_response.status, 200)
  assert_true(
    render_response_body(action_response.body).contains("profiles.update"),
  )
}
