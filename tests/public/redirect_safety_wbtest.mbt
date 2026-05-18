///|
test "is_safe_internal_redirect accepts well-formed internal paths" {
  assert_true(is_safe_internal_redirect("/"))
  assert_true(is_safe_internal_redirect("/posts"))
  assert_true(is_safe_internal_redirect("/posts/42"))
  assert_true(is_safe_internal_redirect("/posts/42?page=2"))
  assert_true(is_safe_internal_redirect("/posts/42#section"))
  assert_true(is_safe_internal_redirect("/users/sign_in?return_to=/home"))
}

///|
test "is_safe_internal_redirect rejects external and unsafe targets" {
  assert_false(is_safe_internal_redirect(""))
  assert_false(is_safe_internal_redirect("posts"))
  assert_false(is_safe_internal_redirect("//evil.com"))
  assert_false(is_safe_internal_redirect("//evil.com/path"))
  assert_false(is_safe_internal_redirect("/\\evil.com"))
  assert_false(is_safe_internal_redirect("http://evil.com"))
  assert_false(is_safe_internal_redirect("https://evil.com"))
  assert_false(is_safe_internal_redirect("javascript:alert(1)"))
  assert_false(is_safe_internal_redirect("data:text/html,<script>"))
}

///|
test "redirect_response refuses to point at external locations" {
  let safe = redirect_response("/dashboard")
  assert_eq(safe.status, 302)
  assert_true(safe.headers.contains(("location", "/dashboard")))
  let external = redirect_response("https://evil.com")
  assert_eq(external.status, 400)
  for header in external.headers {
    assert_false(header.0 == "location")
  }
  let protocol_relative = redirect_response("//evil.com/path")
  assert_eq(protocol_relative.status, 400)
  let js = redirect_response("javascript:alert(1)")
  assert_eq(js.status, 400)
}

///|
test "see_other_response inherits internal-only validation" {
  let safe = see_other_response("/posts/42")
  assert_eq(safe.status, 303)
  let external = see_other_response("https://evil.com/path")
  assert_eq(external.status, 400)
}

///|
test "redirect_response_to_external sends absolute URLs when caller opts in" {
  let response = redirect_response_to_external("https://example.com/oauth/callback")
  assert_eq(response.status, 302)
  assert_true(
    response.headers.contains((
      "location", "https://example.com/oauth/callback",
    )),
  )
  let strips_crlf = redirect_response_to_external(
    "https://example.com/x\r\nset-cookie: forged=1",
  )
  for header in strips_crlf.headers {
    assert_false(header.1.contains("\r"))
    assert_false(header.1.contains("\n"))
  }
}
