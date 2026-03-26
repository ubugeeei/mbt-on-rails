///|
/// Builds the application layout used by the demo pages.
pub fn demo_application_layout() -> @view.LayoutModule {
  @view.layout_module(
    name="application",
    file_path=view_layouts_application(),
    component=demo_application_layout_component(),
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
      name="sessions.create",
      route="/_actions/sessions.create",
      input_fields=[("email", "String"), ("password", "String")],
      output_type="SessionPayload",
      csrf_protected=true,
    ),
    @view.server_action(
      name="sessions.destroy",
      route="/_actions/sessions.destroy",
      input_fields=[],
      output_type="Unit",
      csrf_protected=true,
    ),
    @view.server_action(
      name="posts.create",
      route="/_actions/posts.create",
      input_fields=[("title", "String"), ("slug", "String"), ("body", "String")],
      output_type="PostPayload",
      csrf_protected=true,
    ),
    @view.server_action(
      name="posts.update",
      route="/_actions/posts.update",
      input_fields=[
        ("id", "String"),
        ("title", "String"),
        ("slug", "String"),
        ("body", "String"),
      ],
      output_type="PostPayload",
      csrf_protected=true,
    ),
    @view.server_action(
      name="posts.destroy",
      route="/_actions/posts.destroy",
      input_fields=[("id", "String")],
      output_type="Unit",
      csrf_protected=true,
    ),
    @view.server_action(
      name="posts.publish",
      route="/_actions/posts.publish",
      input_fields=[("id", "String")],
      output_type="PostPayload",
      csrf_protected=true,
    ),
  ]
}

///|
/// Builds the demo home page module.
fn demo_home_page(layout : @view.LayoutModule) -> @view.PageModule {
  @view.page_module(
    route_name="home",
    route_path="/",
    file_path=view_pages_home(),
    title="mbt on rails",
    component=demo_home_page_component(),
  )
  .with_layout(layout)
  .with_metadata("description", "MoonBit on Rails with Vapor Moon delivery")
  .with_loader(
    @view.loader_module(
      name="load_home",
      cache_key="home",
      revalidate_seconds=Some(30),
      depends_on=[],
    ),
  )
  .with_island(demo_post_composer_idle_island())
}

///|
/// Builds the demo sign-in page module.
fn demo_sign_in_page(layout : @view.LayoutModule) -> @view.PageModule {
  let binding = @view.form_binding(
    name="sign_in",
    action_name="sessions.create",
    verb="POST",
    optimistic_key=None,
    redirect_to=Some("/"),
  )
  @view.page_module(
    route_name="sign_in",
    route_path="/sign-in",
    file_path=view_pages_sign_in(),
    title="Sign In",
    component=demo_sign_in_page_component(),
  )
  .with_layout(layout)
  .with_action_name("sessions.create")
  .with_form_builder(
    @view.form_builder(
      name="sign_in_form",
      binding~,
      fields=[
        @view.email_field(
          name="email",
          label="Email",
          autocomplete=Some("email"),
          placeholder=Some("hello@example.com"),
        ),
        @view.password_field(
          name="password",
          label="Password",
          autocomplete=Some("current-password"),
        ),
      ],
      submit_label="Sign in",
      description=Some("Typed sign-in form metadata for the client bridge"),
    ),
  )
}

///|
/// Builds the demo posts index page module.
fn demo_posts_index_page(layout : @view.LayoutModule) -> @view.PageModule {
  @view.page_module(
    route_name="posts_index",
    route_path="/posts",
    file_path=view_pages_posts_index(),
    title="Posts",
    component=demo_posts_index_page_component(),
  )
  .with_layout(layout)
  .with_action_name("posts.create")
  .with_loader(
    @view.loader_module(
      name="load_posts",
      cache_key="posts:index",
      revalidate_seconds=Some(60),
      depends_on=["posts"],
    ),
  )
  .with_dynamic_mode(@view.dynamic_revalidate(60))
  .with_island(demo_post_composer_island("index"))
  .with_form(
    @view.form_binding(
      name="post_create",
      action_name="posts.create",
      verb="POST",
      optimistic_key=Some("posts"),
      redirect_to=Some("/posts"),
    ),
  )
}

///|
/// Builds the demo posts show page module.
fn demo_posts_show_page(layout : @view.LayoutModule) -> @view.PageModule {
  @view.page_module(
    route_name="posts_show",
    route_path="/posts/[id]",
    file_path=view_pages_posts_show(),
    title="Post",
    component=demo_posts_show_page_component(),
  )
  .with_layout(layout)
  .with_action_name("posts.update")
  .with_loader(
    @view.loader_module(
      name="load_post",
      cache_key="posts:show",
      revalidate_seconds=None,
      depends_on=["posts", "authors"],
    ),
  )
  .with_island(demo_like_button_island())
  .with_form(
    @view.form_binding(
      name="post_update",
      action_name="posts.update",
      verb="POST",
      optimistic_key=Some("post"),
      redirect_to=Some("/posts/[id]"),
    ),
  )
}

///|
/// Builds the demo posts new page module.
fn demo_posts_new_page(layout : @view.LayoutModule) -> @view.PageModule {
  @view.page_module(
    route_name="posts_new",
    route_path="/posts/new",
    file_path=view_pages_posts_new(),
    title="New Post",
    component=demo_posts_new_page_component(),
  )
  .with_layout(layout)
  .with_form(
    @view.form_binding(
      name="post_create_page",
      action_name="posts.create",
      verb="POST",
      optimistic_key=None,
      redirect_to=Some("/posts"),
    ),
  )
}

///|
/// Builds the demo posts edit page module.
fn demo_posts_edit_page(layout : @view.LayoutModule) -> @view.PageModule {
  @view.page_module(
    route_name="posts_edit",
    route_path="/posts/[id]/edit",
    file_path=view_pages_posts_edit(),
    title="Edit Post",
    component=demo_posts_edit_page_component(),
  )
  .with_layout(layout)
  .with_loader(
    @view.loader_module(
      name="load_post_for_edit",
      cache_key="posts:edit",
      revalidate_seconds=None,
      depends_on=["posts"],
    ),
  )
  .with_form(
    @view.form_binding(
      name="post_edit",
      action_name="posts.update",
      verb="POST",
      optimistic_key=None,
      redirect_to=Some("/posts/[id]"),
    ),
  )
}
