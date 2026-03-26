///|
/// Builds a minimal page layout used by render-mode tests.
fn render_test_layout() -> LayoutModule {
  layout_module(
    name="application",
    file_path=mbtv_path("examples/demo_blog/views/layouts/application.mbtv"),
    component=server_component(
      name="ApplicationLayout",
      source_path=mbtv_path("examples/demo_blog/views/layouts/application.mbtv"),
      props=[],
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
test "relation sql covers distinct grouping merge pluck exists and none" {
  let schema = model(name="Post", table="posts", columns=[
    string_column("title"),
  ])
  let aggregated = relation_for(schema)
    .select_columns(["posts.author_id", "COUNT(*) AS total"])
    .distinct_records()
    .group_by(["posts.author_id"])
    .having_raw("COUNT(*) > 1")

  assert_eq(
    relation_to_sql(aggregated),
    "SELECT DISTINCT posts.author_id, COUNT(*) AS total FROM posts GROUP BY posts.author_id HAVING COUNT(*) > 1",
  )

  let merged = merge_relation(
    relation_for(schema)
    .where_eq("state", "published")
    .order_by("created_at", descending=true)
    .preload("author"),
    relation_for(schema)
    .where_like("title", "%MoonBit%")
    .reorder_by("id", descending=true)
    .limit_to(3),
  )

  assert_eq(
    relation_to_sql(merged),
    "SELECT * FROM posts WHERE state = 'published' AND title LIKE '%MoonBit%' ORDER BY created_at DESC, id DESC LIMIT 3",
  )
  assert_eq(merged.preloads[0], "author")

  let reversed = reverse_order(
    relation_for(schema)
    .order_by("created_at", descending=true)
    .order_by("title"),
  )
  assert_eq(
    relation_to_sql(reversed),
    "SELECT * FROM posts ORDER BY created_at ASC, title DESC",
  )

  let titles = relation_for(schema).where_eq("state", "published")
  assert_eq(
    pluck_sql(titles, ["title", "slug"]),
    "SELECT title, slug FROM posts WHERE state = 'published'",
  )
  assert_eq(
    exists_sql(none_relation(titles)),
    "SELECT 1 AS one FROM posts WHERE 1=0 AND state = 'published' LIMIT 1",
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
            route_name="render_modes",
            route_path="/render-modes",
            file_path=mbtv_path("examples/demo_blog/views/pages/home.mbtv"),
            title="Render Modes",
            component=server_component(
              name="RenderModesPage",
              source_path=mbtv_path("examples/demo_blog/views/pages/home.mbtv"),
              props=[],
            ),
          ),
          layout,
        ),
        dynamic_force_dynamic(),
      ),
      "robots",
      "noindex",
    ),
    asset_manifest(style_urls=["/assets/app.css"], script_urls=[
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
              name="ManualIsland",
              source_path=mbtv_path(
                "examples/demo_blog/views/components/like_button.mbtv",
              ),
              props=[],
              hydration=hydrate_manual(),
            ),
          ),
          client_component(
            name="IdleIsland",
            source_path=mbtv_path(
              "examples/demo_blog/views/components/like_button.mbtv",
            ),
            props=[],
            hydration=hydrate_idle(),
          ),
        ),
        client_component(
          name="MediaIsland",
          source_path=mbtv_path(
            "examples/demo_blog/views/components/like_button.mbtv",
          ),
          props=[],
          hydration=hydrate_media("(max-width: 700px)"),
        ),
      ),
      client_component(
        name="OnlyIsland",
        source_path=mbtv_path(
          "examples/demo_blog/views/components/like_button.mbtv",
        ),
        props=[],
        hydration=hydrate_only(),
      ),
    ),
    client_component(
      name="DeferredIsland",
      source_path=mbtv_path(
        "examples/demo_blog/views/components/like_button.mbtv",
      ),
      props=[],
      hydration=defer_on_server(),
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
