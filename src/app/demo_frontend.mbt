///|
/// Builds the application layout used by the demo pages.
pub fn demo_application_layout() -> @view.LayoutModule {
  @view.layout_module(
    "application",
    "examples/demo_blog/views/layouts/application.mbtv",
    @view.server_component(
      "ApplicationLayout",
      "examples/demo_blog/views/layouts/application.mbtv",
      [],
    ),
  )
}

///|
/// Builds the page modules used by the demo app.
pub fn demo_pages(layout : @view.LayoutModule) -> Array[@view.PageModule] {
  [
    demo_home_page(layout),
    demo_sign_in_page(layout),
    demo_posts_index_page(layout),
    demo_posts_show_page(layout),
    demo_posts_new_page(layout),
    demo_posts_edit_page(layout),
  ]
}

///|
/// Builds the server actions exposed by the demo app.
pub fn demo_server_actions() -> Array[@view.ServerAction] {
  [
    @view.server_action(
      "sessions.create",
      "/_actions/sessions.create",
      [("email", "String"), ("password", "String")],
      "SessionPayload",
      true,
    ),
    @view.server_action(
      "sessions.destroy",
      "/_actions/sessions.destroy",
      [],
      "Unit",
      true,
    ),
    @view.server_action(
      "posts.create",
      "/_actions/posts.create",
      [("title", "String"), ("slug", "String"), ("body", "String")],
      "PostPayload",
      true,
    ),
    @view.server_action(
      "posts.update",
      "/_actions/posts.update",
      [
        ("id", "String"),
        ("title", "String"),
        ("slug", "String"),
        ("body", "String"),
      ],
      "PostPayload",
      true,
    ),
    @view.server_action(
      "posts.destroy",
      "/_actions/posts.destroy",
      [("id", "String")],
      "Unit",
      true,
    ),
    @view.server_action(
      "posts.publish",
      "/_actions/posts.publish",
      [("id", "String")],
      "PostPayload",
      true,
    ),
  ]
}

///|
/// Builds the demo home page module.
fn demo_home_page(layout : @view.LayoutModule) -> @view.PageModule {
  @view.with_island(
    @view.with_loader(
      @view.with_metadata(
        @view.with_layout(
          @view.page_module(
            "home",
            "/",
            "examples/demo_blog/views/pages/home.mbtv",
            "mbt on rails",
            @view.server_component(
              "HomePage",
              "examples/demo_blog/views/pages/home.mbtv",
              [("title", "mbt on rails")],
            ),
          ),
          layout,
        ),
        "description",
        "MoonBit on Rails with Vapor Moon delivery",
      ),
      @view.loader_module("load_home", "home", Some(30), []),
    ),
    @view.client_component(
      "PostComposer",
      "examples/demo_blog/views/components/post_composer.mbtv",
      [("mode", "home")],
      @view.hydrate_idle(),
    ),
  )
}

///|
/// Builds the demo sign-in page module.
fn demo_sign_in_page(layout : @view.LayoutModule) -> @view.PageModule {
  @view.with_form(
    @view.with_action_name(
      @view.with_layout(
        @view.page_module(
          "sign_in",
          "/sign-in",
          "examples/demo_blog/views/pages/sign_in.mbtv",
          "Sign In",
          @view.server_component(
            "SignInPage",
            "examples/demo_blog/views/pages/sign_in.mbtv",
            [],
          ),
        ),
        layout,
      ),
      "sessions.create",
    ),
    @view.form_binding("sign_in", "sessions.create", "POST", None, Some("/")),
  )
}

///|
/// Builds the demo posts index page module.
fn demo_posts_index_page(layout : @view.LayoutModule) -> @view.PageModule {
  @view.with_form(
    @view.with_island(
      @view.with_dynamic_mode(
        @view.with_loader(
          @view.with_action_name(
            @view.with_layout(
              @view.page_module(
                "posts_index",
                "/posts",
                "examples/demo_blog/views/pages/posts/index.mbtv",
                "Posts",
                @view.server_component(
                  "PostsIndexPage",
                  "examples/demo_blog/views/pages/posts/index.mbtv",
                  [],
                ),
              ),
              layout,
            ),
            "posts.create",
          ),
          @view.loader_module("load_posts", "posts:index", Some(60), ["posts"]),
        ),
        @view.dynamic_revalidate(60),
      ),
      @view.client_component(
        "PostComposer",
        "examples/demo_blog/views/components/post_composer.mbtv",
        [("mode", "index")],
        @view.hydrate_visible(),
      ),
    ),
    @view.form_binding(
      "post_create",
      "posts.create",
      "POST",
      Some("posts"),
      Some("/posts"),
    ),
  )
}

///|
/// Builds the demo posts show page module.
fn demo_posts_show_page(layout : @view.LayoutModule) -> @view.PageModule {
  @view.with_form(
    @view.with_island(
      @view.with_loader(
        @view.with_action_name(
          @view.with_layout(
            @view.page_module(
              "posts_show",
              "/posts/[id]",
              "examples/demo_blog/views/pages/posts/show.mbtv",
              "Post",
              @view.server_component(
                "PostsShowPage",
                "examples/demo_blog/views/pages/posts/show.mbtv",
                [],
              ),
            ),
            layout,
          ),
          "posts.update",
        ),
        @view.loader_module("load_post", "posts:show", None, [
          "posts", "authors",
        ]),
      ),
      @view.client_component(
        "LikeButton",
        "examples/demo_blog/views/components/like_button.mbtv",
        [("kind", "heart")],
        @view.hydrate_load(),
      ),
    ),
    @view.form_binding(
      "post_update",
      "posts.update",
      "POST",
      Some("post"),
      Some("/posts/[id]"),
    ),
  )
}

///|
/// Builds the demo posts new page module.
fn demo_posts_new_page(layout : @view.LayoutModule) -> @view.PageModule {
  @view.with_form(
    @view.with_layout(
      @view.page_module(
        "posts_new",
        "/posts/new",
        "examples/demo_blog/views/pages/posts/new.mbtv",
        "New Post",
        @view.server_component(
          "PostsNewPage",
          "examples/demo_blog/views/pages/posts/new.mbtv",
          [],
        ),
      ),
      layout,
    ),
    @view.form_binding(
      "post_create_page",
      "posts.create",
      "POST",
      None,
      Some("/posts"),
    ),
  )
}

///|
/// Builds the demo posts edit page module.
fn demo_posts_edit_page(layout : @view.LayoutModule) -> @view.PageModule {
  @view.with_form(
    @view.with_loader(
      @view.with_layout(
        @view.page_module(
          "posts_edit",
          "/posts/[id]/edit",
          "examples/demo_blog/views/pages/posts/edit.mbtv",
          "Edit Post",
          @view.server_component(
            "PostsEditPage",
            "examples/demo_blog/views/pages/posts/edit.mbtv",
            [],
          ),
        ),
        layout,
      ),
      @view.loader_module("load_post_for_edit", "posts:edit", None, ["posts"]),
    ),
    @view.form_binding(
      "post_edit",
      "posts.update",
      "POST",
      None,
      Some("/posts/[id]"),
    ),
  )
}
