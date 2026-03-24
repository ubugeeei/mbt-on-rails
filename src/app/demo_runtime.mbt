///|
/// Builds the middleware stack configured by the demo app.
pub fn demo_middlewares() -> Array[@middleware.Middleware] {
  [
    @middleware.with_request_header(
      @middleware.with_response_header(
        @middleware.middleware("request_id", None, [], [], [], None),
        "x-request-id",
        "demo-" + @support.hash_string("/"),
      ),
      "x-request-start",
      "2026-03-25T00:00:00Z",
    ),
    @middleware.with_response_header(
      @middleware.with_response_header(
        @middleware.middleware("security_headers", None, [], [], [], None),
        "x-frame-options",
        "DENY",
      ),
      "x-content-type-options",
      "nosniff",
    ),
    @middleware.halt_with_text(
      "internal_guard",
      "/_internal",
      [@http.http_get()],
      503,
      "Internal endpoints are disabled in the demo app",
    ),
  ]
}

///|
/// Builds the fixtures configured by the demo app.
pub fn demo_fixtures() -> Array[@fixture.FixtureSet] {
  [
    @fixture.fixture_set("users", "users", [
      @fixture.fixture_row(
        "alice",
        @orm.record("users", [
          ("id", "1"),
          ("email", "alice@example.com"),
          ("password_digest", "digest"),
          ("role", "admin"),
        ]),
      ),
      @fixture.fixture_row(
        "bob",
        @orm.record("users", [
          ("id", "2"),
          ("email", "bob@example.com"),
          ("password_digest", "digest"),
          ("role", "editor"),
        ]),
      ),
    ]),
    @fixture.fixture_set("posts", "posts", [
      @fixture.fixture_row(
        "welcome",
        @orm.record("posts", [
          ("id", "42"),
          ("title", "Welcome"),
          ("slug", "welcome"),
          ("body", "hello moonbit"),
          ("author_id", "1"),
        ]),
      ),
    ]),
  ]
}

///|
/// Builds the seed plans configured by the demo app.
pub fn demo_seeds() -> Array[@fixture.SeedPlan] {
  [
    @fixture.seed_plan(
      "bootstrap",
      [
        @orm.record("users", [
          ("id", "10"),
          ("email", "seed@example.com"),
          ("password_digest", "digest"),
          ("role", "user"),
        ]),
      ],
      [
        @job.enqueued_job(
          @job.job("search.reindex", "default", [("scope", "String")], 2, None),
          [("scope", "posts")],
          "",
          0,
        ),
      ],
    ),
  ]
}
