///|
test "route parsing and matching cover params catchalls and optional rest segments" {
  let colon = parse_route_pattern("/users/:id")
  let catchall = parse_route_pattern("/assets/[...path]")
  let optional = parse_route_pattern("/docs/[[...parts]]")
  let splat = parse_route_pattern("/*")

  match match_route(colon, "/users/42") {
    Some(params) => assert_eq(params[0].1, "42")
    None => assert_true(false)
  }
  match match_route(catchall, "/assets/images/icons/logo.svg") {
    Some(params) => assert_eq(params[0].1, "images/icons/logo.svg")
    None => assert_true(false)
  }
  match match_route(optional, "/docs") {
    Some(params) => assert_eq(params.length(), 0)
    None => assert_true(false)
  }
  match match_route(optional, "/docs/guides/start") {
    Some(params) => assert_eq(params[0].1, "guides/start")
    None => assert_true(false)
  }
  match match_route(splat, "/one/two") {
    Some(params) => assert_eq(params[0].1, "one/two")
    None => assert_true(false)
  }
  match match_route(colon, "/users") {
    Some(_) => assert_true(false)
    None => assert_true(true)
  }
}

///|
test "build_path and recognize rebuild concrete routes and honor verbs" {
  let post_route = route(
    "post_show",
    http_get(),
    "/posts/[id]/[[...rest]]",
    "PostsController",
    "show",
    None,
  )
  let asset_route = route(
    "asset",
    http_get(),
    "/assets/[...path]",
    "AssetsController",
    "show",
    None,
  )
  assert_eq(build_path(post_route, [("id", "42")]), "/posts/42")
  assert_eq(
    build_path(post_route, [("id", "42"), ("rest", "comments/1")]),
    "/posts/42/comments/1",
  )
  assert_eq(
    build_path(asset_route, [("path", "images/logo.svg")]),
    "/assets/images/logo.svg",
  )
  assert_eq(build_path(asset_route, []), "/assets/*")

  let routes = [
    route("show", http_get(), "/posts/[id]", "PostsController", "show", None),
    route(
      "update",
      http_post(),
      "/posts/[id]",
      "PostsController",
      "update",
      None,
    ),
  ]
  match
    recognize(routes, request(http_post(), "/posts/42/", [], [], None, "")) {
    Some(matched) => assert_eq(matched.route.name, "update")
    None => assert_true(false)
  }
  match
    recognize(routes, request(http_delete(), "/posts/42", [], [], None, "")) {
    Some(_) => assert_true(false)
    None => assert_true(true)
  }
}

///|
test "response builders preserve status content types and body rendering" {
  let json = json_response(422, "{\"error\":true}")
  let text = ok_text("ok")
  let redirected = redirect_response("/posts")
  let empty = no_content_response()

  assert_eq(json.status, 422)
  assert_eq(json.headers[0].1, "application/json; charset=utf-8")
  assert_eq(render_response_body(json.body), "{\"error\":true}")
  assert_eq(render_response_body(text.body), "ok")
  assert_eq(render_response_body(redirected.body), "Redirecting to /posts")
  assert_eq(render_response_body(empty.body), "")
}
