///|
test "tag_request_with_id adds the resolved id back onto the request" {
  let req = request(
    verb=http_get(),
    path="/",
    query=[],
    form=[],
    session_id=None,
    body="",
  )
  let result = tag_request_with_id(req, "x-request-id", "gen-42")
  assert_eq(result.1, "gen-42")
  assert_true(request_header(result.0, "x-request-id") == Some("gen-42"))
}

///|
test "tag_request_with_id prefers an existing id when present" {
  let req = request(
    verb=http_get(),
    path="/",
    query=[],
    form=[],
    session_id=None,
    body="",
  )
  let with_existing = append_request_header(
    req, "x-request-id", "upstream-id-1",
  )
  let result = tag_request_with_id(with_existing, "x-request-id", "fallback")
  assert_eq(result.1, "upstream-id-1")
}

///|
test "tag_response_with_request_id appends the header value" {
  let resp = ok_text("ok")
  let tagged = tag_response_with_request_id(resp, "x-request-id", "abc-123")
  assert_true(tagged.headers.contains(("x-request-id", "abc-123")))
}

///|
test "apply_trusted_proxy surfaces resolved client metadata" {
  let req = request(
    verb=http_get(),
    path="/",
    query=[],
    form=[],
    session_id=None,
    body="",
  )
  let with_headers = append_request_header(
    append_request_header(
      append_request_header(
        req, "x-forwarded-for", "203.0.113.10, 198.51.100.7, 10.0.0.1",
      ),
      "x-forwarded-proto",
      "HTTPS",
    ),
    "x-forwarded-host",
    "Example.COM",
  )
  let resolved = apply_trusted_proxy(with_headers, ["10.0.0.1"])
  assert_true(resolved_client_ip(resolved) == Some("198.51.100.7"))
  assert_true(resolved_client_proto(resolved) == Some("https"))
  assert_true(resolved_client_host(resolved) == Some("example.com"))
}

///|
test "apply_trusted_proxy leaves the request alone when no forwarded headers exist" {
  let req = request(
    verb=http_get(),
    path="/",
    query=[],
    form=[],
    session_id=None,
    body="",
  )
  let resolved = apply_trusted_proxy(req, ["10.0.0.1"])
  assert_true(resolved_client_ip(resolved) is None)
  assert_true(resolved_client_proto(resolved) is None)
  assert_true(resolved_client_host(resolved) is None)
}
