///|
/// Runtime and delivery helpers that complement the main facade.

///|
pub using @middleware {
  type Middleware,
  apply_request_middleware,
  apply_response_middleware,
  halt_with_text,
  middleware,
  middleware_summary,
  with_request_header,
  with_response_header,
}

///|
pub using @fixture {
  type FixtureRow,
  type FixtureSet,
  type SeedPlan,
  apply_seed,
  fixture_row,
  fixture_set,
  fixture_summary,
  load_fixture_set,
  load_fixtures,
  seed_plan,
  seed_summary,
}

///|
pub using @turbo {
  type TurboStream,
  type TurboStreamAction,
  append_stream,
  ok_turbo_stream,
  prepend_stream,
  remove_stream,
  render_turbo_stream,
  replace_stream,
  turbo_stream,
  update_stream,
}
