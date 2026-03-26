///|
/// Builds a minimal page layout used by render-mode tests.
fn render_test_layout() -> LayoutModule {
  layout_module(
    "application",
    mbtv_path("examples/demo_blog/views/layouts/application.mbtv"),
    server_component(
      "ApplicationLayout",
      mbtv_path("examples/demo_blog/views/layouts/application.mbtv"),
      [],
    ),
  )
}

///|
test "relation sql covers joins selects predicates counts and offsets" {
  let schema = model(name="Post", table="posts", columns=[
    string_column("title"),
  ])
  let relation = offset_by(
    limit_to(
      order_by(
        preload(
          join_relation(
            select_columns(
              where_raw(
                where_in(
                  where_lt(
                    where_gt(
                      where_not_eq(
                        where_eq(relation_for(schema), "account_id", "7"),
                        "state",
                        "archived",
                      ),
                      "views",
                      "10",
                    ),
                    "likes",
                    "100",
                  ),
                  "id",
                  ["1", "2", "3"],
                ),
                "published = TRUE",
              ),
              ["posts.id", "posts.title"],
            ),
            "INNER JOIN users ON users.id = posts.user_id",
          ),
          "author",
        ),
        "title",
        descending=false,
      ),
      20,
    ),
    40,
  )

  assert_eq(relation.preloads[0], "author")
  assert_eq(
    relation_to_sql(relation),
    "SELECT posts.id, posts.title FROM posts INNER JOIN users ON users.id = posts.user_id WHERE account_id = 7 AND state <> 'archived' AND views > 10 AND likes < 100 AND id IN (1, 2, 3) AND published = TRUE ORDER BY title ASC LIMIT 20 OFFSET 40",
  )
  assert_eq(
    count_sql(relation),
    "SELECT COUNT(*) FROM posts INNER JOIN users ON users.id = posts.user_id WHERE account_id = 7 AND state <> 'archived' AND views > 10 AND likes < 100 AND id IN (1, 2, 3) AND published = TRUE ORDER BY title ASC LIMIT 20 OFFSET 40",
  )
}

///|
test "render_page covers hydration variants assets metadata and dynamic modes" {
  let layout = render_test_layout()
  let base = with_assets(
    with_metadata(
      with_dynamic_mode(
        with_layout(
          page_module(
            "render_modes",
            "/render-modes",
            mbtv_path("examples/demo_blog/views/pages/home.mbtv"),
            "Render Modes",
            server_component(
              "RenderModesPage",
              mbtv_path("examples/demo_blog/views/pages/home.mbtv"),
              [],
            ),
          ),
          layout,
        ),
        dynamic_force_dynamic(),
      ),
      "robots",
      "noindex",
    ),
    asset_manifest(["/assets/app.css"], [
      "/assets/hydrate.js", "/assets/page.js",
    ]),
  )
  let page = with_island(
    with_island(
      with_island(
        with_island(
          with_island(
            base,
            client_component(
              "ManualIsland",
              mbtv_path("examples/demo_blog/views/components/like_button.mbtv"),
              [],
              hydrate_manual(),
            ),
          ),
          client_component(
            "IdleIsland",
            mbtv_path("examples/demo_blog/views/components/like_button.mbtv"),
            [],
            hydrate_idle(),
          ),
        ),
        client_component(
          "MediaIsland",
          mbtv_path("examples/demo_blog/views/components/like_button.mbtv"),
          [],
          hydrate_media("(max-width: 700px)"),
        ),
      ),
      client_component(
        "OnlyIsland",
        mbtv_path("examples/demo_blog/views/components/like_button.mbtv"),
        [],
        hydrate_only(),
      ),
    ),
    client_component(
      "DeferredIsland",
      mbtv_path("examples/demo_blog/views/components/like_button.mbtv"),
      [],
      defer_on_server(),
    ),
  )
  let rendered = render_page(page, [], [], [])

  assert_true(rendered.html.contains("data-mbor-hydration=\"manual\""))
  assert_true(rendered.html.contains("data-mbor-hydration=\"client:idle\""))
  assert_true(
    rendered.html.contains(
      "data-mbor-hydration=\"client:media=(max-width: 700px)\"",
    ),
  )
  assert_true(rendered.html.contains("data-mbor-hydration=\"client:only\""))
  assert_true(rendered.html.contains("data-mbor-hydration=\"server:defer\""))
  assert_true(rendered.html.contains("data-mbor-dynamic=\"force-dynamic\""))
  assert_true(rendered.html.contains("content=\"noindex\""))
  assert_true(rendered.html.contains("href=\"/assets/app.css\""))
  assert_true(rendered.html.contains("src=\"/assets/page.js\""))
  assert_true(
    rendered.router_manifest_entry.contains(
      "\"dynamic_mode\": \"force-dynamic\"",
    ),
  )

  let static_page = render_page_manifest_entry(
    with_dynamic_mode(base, dynamic_force_static()),
  )
  assert_true(static_page.contains("\"dynamic_mode\": \"force-static\""))
}
