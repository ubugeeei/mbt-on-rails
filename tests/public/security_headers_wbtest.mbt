///|
test "nosniff_middleware sets X-Content-Type-Options on every response" {
  let layers = [nosniff_middleware()]
  let req = request(
    verb=http_get(),
    path="/",
    query=[],
    form=[],
    session_id=None,
    body="",
  )
  let resp = apply_response_middleware(layers, req, ok_text("ok"))
  assert_true(resp.headers.contains(("x-content-type-options", "nosniff")))
}

///|
test "frame_options_middleware emits DENY or SAMEORIGIN as configured" {
  let req = request(
    verb=http_get(),
    path="/",
    query=[],
    form=[],
    session_id=None,
    body="",
  )
  let deny = apply_response_middleware(
    [frame_options_middleware(frame_options_deny())],
    req,
    ok_text("ok"),
  )
  assert_true(deny.headers.contains(("x-frame-options", "DENY")))
  let same = apply_response_middleware(
    [frame_options_middleware(frame_options_same_origin())],
    req,
    ok_text("ok"),
  )
  assert_true(same.headers.contains(("x-frame-options", "SAMEORIGIN")))
}

///|
test "hsts_middleware composes a Strict-Transport-Security value" {
  let req = request(
    verb=http_get(),
    path="/",
    query=[],
    form=[],
    session_id=None,
    body="",
  )
  let response = apply_response_middleware(
    [hsts_middleware(63072000, true, true)],
    req,
    ok_text("ok"),
  )
  assert_true(
    response.headers.contains(
      (
        "strict-transport-security", "max-age=63072000; includeSubDomains; preload",
      ),
    ),
  )
  let minimal = apply_response_middleware(
    [hsts_middleware(3600, false, false)],
    req,
    ok_text("ok"),
  )
  assert_true(
    minimal.headers.contains(("strict-transport-security", "max-age=3600")),
  )
}

///|
test "referrer_policy_middleware emits the configured policy" {
  let req = request(
    verb=http_get(),
    path="/",
    query=[],
    form=[],
    session_id=None,
    body="",
  )
  let response = apply_response_middleware(
    [referrer_policy_middleware("strict-origin-when-cross-origin")],
    req,
    ok_text("ok"),
  )
  assert_true(
    response.headers.contains(
      ("referrer-policy", "strict-origin-when-cross-origin"),
    ),
  )
}

///|
test "content_security_policy_value renders only configured directives" {
  let strict = strict_content_security_policy()
  let value = content_security_policy_value(strict)
  assert_true(value.contains("default-src 'self'"))
  assert_true(value.contains("frame-ancestors 'none'"))
  assert_true(value.contains("object-src 'none'"))
  let empty : Array[String] = []
  let minimal : ContentSecurityPolicy = {
    default_src: ["'self'"],
    script_src: empty,
    style_src: empty,
    img_src: empty,
    connect_src: empty,
    font_src: empty,
    frame_ancestors: empty,
    object_src: empty,
    base_uri: empty,
    form_action: empty,
  }
  assert_eq(content_security_policy_value(minimal), "default-src 'self'")
}

///|
test "cors_middleware halts preflight requests and tags every other response" {
  let config : CorsConfig = {
    allowed_origin: "https://app.example.com",
    allowed_methods: [http_get(), http_post()],
    allowed_headers: ["content-type", "x-csrf-token"],
    allow_credentials: true,
    max_age_seconds: 600,
  }
  let layers = cors_middleware(config)
  let preflight = request(
    verb=http_options(),
    path="/api/posts",
    query=[],
    form=[],
    session_id=None,
    body="",
  )
  let outcome = apply_request_middleware(layers, preflight)
  match outcome.1 {
    Some(response) => {
      assert_eq(response.status, 204)
      assert_true(
        response.headers.contains(
          ("access-control-allow-origin", "https://app.example.com"),
        ),
      )
      assert_true(
        response.headers.contains(("access-control-allow-methods", "GET, POST")),
      )
      assert_true(
        response.headers.contains(
          ("access-control-allow-headers", "content-type, x-csrf-token"),
        ),
      )
      assert_true(
        response.headers.contains(("access-control-allow-credentials", "true")),
      )
      assert_true(response.headers.contains(("access-control-max-age", "600")))
    }
    None => assert_true(false)
  }
  let normal = request(
    verb=http_get(),
    path="/api/posts",
    query=[],
    form=[],
    session_id=None,
    body="",
  )
  let response = apply_response_middleware(layers, normal, ok_text("ok"))
  assert_true(
    response.headers.contains(
      ("access-control-allow-origin", "https://app.example.com"),
    ),
  )
  assert_true(
    response.headers.contains(("access-control-allow-credentials", "true")),
  )
}

///|
test "default_security_headers_bundle assembles the opinionated stack" {
  let layers = default_security_headers_bundle()
  assert_eq(layers.length(), 5)
  let req = request(
    verb=http_get(),
    path="/",
    query=[],
    form=[],
    session_id=None,
    body="",
  )
  let resp = apply_response_middleware(layers, req, ok_text("ok"))
  let header_names : Array[String] = []
  for header in resp.headers {
    header_names.push(header.0)
  }
  assert_true(header_names.contains("x-content-type-options"))
  assert_true(header_names.contains("x-frame-options"))
  assert_true(header_names.contains("referrer-policy"))
  assert_true(header_names.contains("content-security-policy"))
  assert_true(header_names.contains("strict-transport-security"))
}
