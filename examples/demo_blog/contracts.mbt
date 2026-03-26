///|
/// Builds the layout component contract used by the demo app.
pub fn demo_application_layout_component() -> @view.VaporComponentRef {
  @view.server_component(
    name="ApplicationLayout",
    source_path=view_layouts_application(),
    props=[],
  ).with_contract(@view.server_contract([], true))
}

///|
/// Builds the home page server component used by the demo app.
pub fn demo_home_page_component() -> @view.VaporComponentRef {
  @view.server_component(name="HomePage", source_path=view_pages_home(), props=[
    ("title", "mbt on rails"),
  ])
  .with_fallback("<div class=\"mbor-shell\">Loading home...</div>")
  .with_contract(
    @view.server_contract(
      [@view.prop_contract("title", "String", true, "Hero title for the page")],
      true,
    ),
  )
}

///|
/// Builds the sign-in page server component used by the demo app.
pub fn demo_sign_in_page_component() -> @view.VaporComponentRef {
  @view.server_component(name="SignInPage", source_path=view_pages_sign_in(), props=[])
  .with_fallback("<div class=\"mbor-shell\">Loading sign in...</div>")
  .with_contract(@view.server_contract([], true))
}

///|
/// Builds the posts index server component used by the demo app.
pub fn demo_posts_index_page_component() -> @view.VaporComponentRef {
  @view.server_component(
    name="PostsIndexPage",
    source_path=view_pages_posts_index(),
    props=[],
  ).with_contract(@view.server_contract([], true))
}

///|
/// Builds the posts show server component used by the demo app.
pub fn demo_posts_show_page_component() -> @view.VaporComponentRef {
  @view.server_component(
    name="PostsShowPage",
    source_path=view_pages_posts_show(),
    props=[],
  ).with_contract(@view.server_contract([], true))
}

///|
/// Builds the posts new server component used by the demo app.
pub fn demo_posts_new_page_component() -> @view.VaporComponentRef {
  @view.server_component(
    name="PostsNewPage",
    source_path=view_pages_posts_new(),
    props=[],
  ).with_contract(@view.server_contract([], true))
}

///|
/// Builds the posts edit server component used by the demo app.
pub fn demo_posts_edit_page_component() -> @view.VaporComponentRef {
  @view.server_component(
    name="PostsEditPage",
    source_path=view_pages_posts_edit(),
    props=[],
  ).with_contract(@view.server_contract([], true))
}

///|
/// Builds the post composer island used by the demo app.
pub fn demo_post_composer_island(mode : String) -> @view.VaporComponentRef {
  @view.client_component(
    name="PostComposer",
    source_path=view_components_post_composer(),
    props=[("mode", mode)],
    hydration=@view.hydrate_visible(),
  )
  .with_fallback("<div class=\"composer-shell\">Preparing composer...</div>")
  .with_contract(
    @view.client_contract([
      @view.prop_contract("mode", "String", true, "Composer mode selector"),
    ]),
  )
}

///|
/// Builds the idle-hydrated post composer island used on the home page.
pub fn demo_post_composer_idle_island() -> @view.VaporComponentRef {
  @view.client_component(
    name="PostComposer",
    source_path=view_components_post_composer(),
    props=[("mode", "home")],
    hydration=@view.hydrate_idle(),
  )
  .with_fallback("<div class=\"composer-shell\">Preparing composer...</div>")
  .with_contract(
    @view.client_contract([
      @view.prop_contract("mode", "String", true, "Composer mode selector"),
    ]),
  )
}

///|
/// Builds the like button island used by the demo app.
pub fn demo_like_button_island() -> @view.VaporComponentRef {
  @view.client_component(
    name="LikeButton",
    source_path=view_components_like_button(),
    props=[("kind", "heart")],
    hydration=@view.hydrate_load(),
  )
  .with_fallback(
    "<button type=\"button\" class=\"like-button\">12 likes</button>",
  )
  .with_contract(
    @view.client_contract([
      @view.prop_contract("kind", "String", true, "Visual reaction kind"),
    ]),
  )
}
