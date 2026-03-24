///|
/// Builds the layout component contract used by the demo app.
pub fn demo_application_layout_component() -> @view.VaporComponentRef {
  @view.with_contract(
    @view.server_component(
      "ApplicationLayout",
      "examples/demo_blog/views/layouts/application.mbtv",
      [],
    ),
    @view.server_contract([], true),
  )
}

///|
/// Builds the home page server component used by the demo app.
pub fn demo_home_page_component() -> @view.VaporComponentRef {
  @view.with_contract(
    @view.with_fallback(
      @view.server_component(
        "HomePage",
        "examples/demo_blog/views/pages/home.mbtv",
        [("title", "mbt on rails")],
      ),
      "<div class=\"mbor-shell\">Loading home...</div>",
    ),
    @view.server_contract(
      [@view.prop_contract("title", "String", true, "Hero title for the page")],
      true,
    ),
  )
}

///|
/// Builds the sign-in page server component used by the demo app.
pub fn demo_sign_in_page_component() -> @view.VaporComponentRef {
  @view.with_contract(
    @view.with_fallback(
      @view.server_component(
        "SignInPage",
        "examples/demo_blog/views/pages/sign_in.mbtv",
        [],
      ),
      "<div class=\"mbor-shell\">Loading sign in...</div>",
    ),
    @view.server_contract([], true),
  )
}

///|
/// Builds the posts index server component used by the demo app.
pub fn demo_posts_index_page_component() -> @view.VaporComponentRef {
  @view.with_contract(
    @view.server_component(
      "PostsIndexPage",
      "examples/demo_blog/views/pages/posts/index.mbtv",
      [],
    ),
    @view.server_contract([], true),
  )
}

///|
/// Builds the posts show server component used by the demo app.
pub fn demo_posts_show_page_component() -> @view.VaporComponentRef {
  @view.with_contract(
    @view.server_component(
      "PostsShowPage",
      "examples/demo_blog/views/pages/posts/show.mbtv",
      [],
    ),
    @view.server_contract([], true),
  )
}

///|
/// Builds the posts new server component used by the demo app.
pub fn demo_posts_new_page_component() -> @view.VaporComponentRef {
  @view.with_contract(
    @view.server_component(
      "PostsNewPage",
      "examples/demo_blog/views/pages/posts/new.mbtv",
      [],
    ),
    @view.server_contract([], true),
  )
}

///|
/// Builds the posts edit server component used by the demo app.
pub fn demo_posts_edit_page_component() -> @view.VaporComponentRef {
  @view.with_contract(
    @view.server_component(
      "PostsEditPage",
      "examples/demo_blog/views/pages/posts/edit.mbtv",
      [],
    ),
    @view.server_contract([], true),
  )
}

///|
/// Builds the post composer island used by the demo app.
pub fn demo_post_composer_island(mode : String) -> @view.VaporComponentRef {
  @view.with_contract(
    @view.with_fallback(
      @view.client_component(
        "PostComposer",
        "examples/demo_blog/views/components/post_composer.mbtv",
        [("mode", mode)],
        @view.hydrate_visible(),
      ),
      "<div class=\"composer-shell\">Preparing composer...</div>",
    ),
    @view.client_contract([
      @view.prop_contract("mode", "String", true, "Composer mode selector"),
    ]),
  )
}

///|
/// Builds the idle-hydrated post composer island used on the home page.
pub fn demo_post_composer_idle_island() -> @view.VaporComponentRef {
  @view.with_contract(
    @view.with_fallback(
      @view.client_component(
        "PostComposer",
        "examples/demo_blog/views/components/post_composer.mbtv",
        [("mode", "home")],
        @view.hydrate_idle(),
      ),
      "<div class=\"composer-shell\">Preparing composer...</div>",
    ),
    @view.client_contract([
      @view.prop_contract("mode", "String", true, "Composer mode selector"),
    ]),
  )
}

///|
/// Builds the like button island used by the demo app.
pub fn demo_like_button_island() -> @view.VaporComponentRef {
  @view.with_contract(
    @view.with_fallback(
      @view.client_component(
        "LikeButton",
        "examples/demo_blog/views/components/like_button.mbtv",
        [("kind", "heart")],
        @view.hydrate_load(),
      ),
      "<button type=\"button\" class=\"like-button\">12 likes</button>",
    ),
    @view.client_contract([
      @view.prop_contract("kind", "String", true, "Visual reaction kind"),
    ]),
  )
}
