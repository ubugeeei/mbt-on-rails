///|
test "parse_forwarded_chain splits and trims while dropping empty hops" {
  assert_eq(parse_forwarded_chain(""), [])
  assert_eq(parse_forwarded_chain("203.0.113.10"), ["203.0.113.10"])
  assert_eq(
    parse_forwarded_chain("203.0.113.10, 198.51.100.7, 10.0.0.1"),
    ["203.0.113.10", "198.51.100.7", "10.0.0.1"],
  )
  assert_eq(parse_forwarded_chain("a, , b"), ["a", "b"])
}

///|
test "parse_forwarded_for skips trusted proxies right-to-left" {
  let trusted = ["10.0.0.1", "10.0.0.2"]
  match parse_forwarded_for("203.0.113.10, 198.51.100.7, 10.0.0.1", trusted) {
    Some(ip) => assert_eq(ip, "198.51.100.7")
    None => assert_true(false)
  }
  match parse_forwarded_for("203.0.113.10", trusted) {
    Some(ip) => assert_eq(ip, "203.0.113.10")
    None => assert_true(false)
  }
  match parse_forwarded_for("10.0.0.1, 10.0.0.2", trusted) {
    Some(ip) => assert_eq(ip, "10.0.0.1")
    None => assert_true(false)
  }
  match parse_forwarded_for("", trusted) {
    Some(_) => assert_true(false)
    None => assert_true(true)
  }
}

///|
test "parse_forwarded_leftmost returns the first hop in lowercase" {
  match parse_forwarded_leftmost("HTTPS, http") {
    Some(value) => assert_eq(value, "https")
    None => assert_true(false)
  }
  match parse_forwarded_leftmost("") {
    Some(_) => assert_true(false)
    None => assert_true(true)
  }
}

///|
test "resolve_request_id reuses upstream id when present" {
  let req = request(
    verb=http_get(),
    path="/",
    query=[],
    form=[],
    session_id=None,
    body="",
  )
  let with_header = append_request_header(req, "x-request-id", "req-abc-123")
  assert_eq(
    resolve_request_id(with_header, "x-request-id", "fallback"),
    "req-abc-123",
  )
}

///|
test "resolve_request_id falls back when no header is present" {
  let req = request(
    verb=http_get(),
    path="/",
    query=[],
    form=[],
    session_id=None,
    body="",
  )
  assert_eq(resolve_request_id(req, "x-request-id", "gen-42"), "gen-42")
}

///|
test "resolve_request_id sanitises injection-shaped header values" {
  let req = request(
    verb=http_get(),
    path="/",
    query=[],
    form=[],
    session_id=None,
    body="",
  )
  let injected = append_request_header(
    req,
    "x-request-id",
    "ok\r\nset-cookie: forged=1",
  )
  let resolved = resolve_request_id(injected, "x-request-id", "fallback")
  assert_false(resolved.contains("\r"))
  assert_false(resolved.contains("\n"))
  assert_false(resolved.contains(":"))
  assert_true(resolved.has_prefix("ok"))
  let only_unsafe = append_request_header(
    req,
    "x-request-id",
    "////",
  )
  assert_eq(
    resolve_request_id(only_unsafe, "x-request-id", "fallback-id"),
    "fallback-id",
  )
}
