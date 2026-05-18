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
    name="post_show",
    verb=http_get(),
    path="/posts/[id]/[[...rest]]",
    controller="PostsController",
    action="show",
    page_name=None,
  )
  let asset_route = route(
    name="asset",
    verb=http_get(),
    path="/assets/[...path]",
    controller="AssetsController",
    action="show",
    page_name=None,
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
    route(
      name="show",
      verb=http_get(),
      path="/posts/[id]",
      controller="PostsController",
      action="show",
      page_name=None,
    ),
    route(
      name="update",
      verb=http_post(),
      path="/posts/[id]",
      controller="PostsController",
      action="update",
      page_name=None,
    ),
  ]
  match
    recognize(
      routes,
      request(
        verb=http_post(),
        path="/posts/42/",
        query=[],
        form=[],
        session_id=None,
        body="",
      ),
    ) {
    Some(matched) => assert_eq(matched.route.name, "update")
    None => assert_true(false)
  }
  match
    recognize(
      routes,
      request(
        verb=http_delete(),
        path="/posts/42",
        query=[],
        form=[],
        session_id=None,
        body="",
      ),
    ) {
    Some(_) => assert_true(false)
    None => assert_true(true)
  }
}

///|
test "response builders preserve status content types and body rendering" {
  let json = json_response(422, "{\"error\":true}")
  let text = ok_text("ok")
  let created = created_json("{\"id\":42}", location=Some("/posts/42"))
  let accepted = accepted_json("{\"queued\":true}")
  let redirected = redirect_response("/posts")
  let see_other = see_other_response("/posts/42")
  let unauthorized = unauthorized_response()
  let forbidden = forbidden_response(message="blocked")
  let invalid = unprocessable_entity_response()
  let preview = signed_cookie(name="preview", value="token-1", secret="secret")
  let with_cookie = append_set_cookie(ok_text("ok"), preview)
  let empty = no_content_response()

  assert_eq(json.status, 422)
  assert_eq(json.headers[0].1, "application/json; charset=utf-8")
  assert_eq(created.status, 201)
  assert_true(created.headers.contains(("location", "/posts/42")))
  assert_eq(accepted.status, 202)
  assert_eq(render_response_body(json.body), "{\"error\":true}")
  assert_eq(render_response_body(text.body), "ok")
  assert_eq(render_response_body(redirected.body), "Redirecting to /posts")
  assert_eq(see_other.status, 303)
  assert_eq(render_response_body(see_other.body), "Redirecting to /posts/42")
  assert_eq(unauthorized.status, 401)
  assert_eq(forbidden.status, 403)
  assert_eq(render_response_body(forbidden.body), "blocked")
  assert_eq(invalid.status, 422)
  assert_true(
    with_cookie.headers.contains(("set-cookie", cookie_header(preview))),
  )
  assert_eq(render_response_body(empty.body), "")
}

///|
test "request helpers decode cookies csrf tokens and session stores" {
  let config = default_auth_config()
  let session = issue_session("42", "browser")
  let store = session_store_for_config(config~, remember_me=false)
  let remember_store = session_store_for_config(config~, remember_me=true)
  let cache_store = cache_session_store(key="_cache_session")
  let redis_store = redis_session_store(key="_redis_session")
  let cross_site_store = cookie_session_store(
    key="_cross_site_session",
    secure=false,
    same_site=cookie_same_site_none(),
    signing_secret=Some(config.secret_key_base),
  )
  let session_cookie_value = session_cookie_with_store(store~, session~)
  let remember_cookie_value = session_cookie_with_store(
    store=remember_store,
    session~,
  )
  let cross_site_cookie_value = session_cookie_with_store(
    store=cross_site_store,
    session~,
  )
  let current = append_request_header(
    append_request_header(
      request(
        verb=http_post(),
        path="/posts",
        query=[],
        form=[("authenticity_token", "from-form")],
        session_id=None,
        body="",
      ),
      "Cookie",
      config.session_cookie + "=" + session_cookie_value.value,
    ),
    "X-CSRF-Token",
    session.csrf_token,
  )
  let remembered = append_request_header(
    request(
      verb=http_get(),
      path="/posts",
      query=[],
      form=[],
      session_id=None,
      body="",
    ),
    "cookie",
    config.remember_cookie + "=" + remember_cookie_value.value,
  )
  let forged_cache = append_request_header(
    request(
      verb=http_get(),
      path="/posts",
      query=[],
      form=[],
      session_id=None,
      body="",
    ),
    "cookie",
    "_cache_session=forged-session-id",
  )
  let forged_redis = append_request_header(
    request(
      verb=http_get(),
      path="/posts",
      query=[],
      form=[],
      session_id=None,
      body="",
    ),
    "cookie",
    "_redis_session=forged-session-id",
  )

  assert_true(
    request_header(current, "cookie") ==
    Some(config.session_cookie + "=" + session_cookie_value.value),
  )
  assert_true(
    request_cookie(current, config.session_cookie) ==
    Some(session_cookie_value.value),
  )
  assert_eq(request_cookies(current).length(), 1)
  assert_true(
    signed_request_cookie(
      current,
      config.session_cookie,
      config.secret_key_base,
    ) ==
    Some(session.id),
  )
  assert_true(request_session_id(current, store) == Some(session.id))
  assert_true(request_session_id(forged_cache, cache_store) == None)
  assert_true(request_session_id(forged_redis, redis_store) == None)
  assert_true(request_csrf_token(current, config) == Some(session.csrf_token))
  assert_true(cross_site_store.secure)
  assert_true(cross_site_cookie_value.secure)
  assert_true(cookie_header(cross_site_cookie_value).contains("Secure"))
  assert_true(cookie_header(cross_site_cookie_value).contains("SameSite=None"))
  assert_true(
    request_csrf_token(
      request(
        verb=http_post(),
        path="/posts",
        query=[],
        form=[("authenticity_token", "from-form")],
        session_id=None,
        body="",
      ),
      config,
    ) ==
    Some("from-form"),
  )
  assert_true(
    with_request_session(current, store~).session_id == Some(session.id),
  )
  assert_true(
    with_request_session(
      remembered,
      store~,
      fallback_store=Some(remember_store),
    ).session_id ==
    Some(session.id),
  )
}
