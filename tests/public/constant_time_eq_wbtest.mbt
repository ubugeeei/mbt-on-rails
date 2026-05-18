///|
test "constant_time_eq accepts identical strings of every shape we care about" {
  assert_true(constant_time_eq("", ""))
  assert_true(constant_time_eq("a", "a"))
  assert_true(
    constant_time_eq(
      "csrf_18394701239847012394871029384701923847", "csrf_18394701239847012394871029384701923847",
    ),
  )
  assert_true(
    constant_time_eq("token--abc--def--ghi--xyz", "token--abc--def--ghi--xyz"),
  )
  assert_true(constant_time_eq("非ASCII文字", "非ASCII文字"))
}

///|
test "constant_time_eq rejects strings that differ anywhere along the walk" {
  assert_false(constant_time_eq("abc", "abd"))
  assert_false(constant_time_eq("abc", "xbc"))
  assert_false(constant_time_eq("abc", "axc"))
  let long_a = "csrf_18394701239847012394871029384701923847"
  let long_b = "csrf_18394701239847012394871029384701923848"
  assert_false(constant_time_eq(long_a, long_b))
  let early_diff_a = "Xsrf_18394701239847012394871029384701923847"
  assert_false(constant_time_eq(early_diff_a, long_a))
}

///|
test "constant_time_eq rejects length mismatches without early return" {
  assert_false(constant_time_eq("abc", "abcd"))
  assert_false(constant_time_eq("abcd", "abc"))
  assert_false(constant_time_eq("", "a"))
  assert_false(constant_time_eq("a", ""))
  assert_false(constant_time_eq("token", "token--"))
  assert_false(
    constant_time_eq(
      "csrf_18394701239847012394871029384701923847", "csrf_18394701239847012394871029384701923847x",
    ),
  )
}

///|
test "csrf_valid uses constant-time comparison and still distinguishes tokens" {
  let session = issue_session(
    "user-1",
    "browser",
    entropy=Some("entropy-a"),
    secret=Some("secret"),
  )
  assert_true(csrf_valid(Some(session), Some(session.csrf_token)))
  let tampered = session.csrf_token + "x"
  assert_false(csrf_valid(Some(session), Some(tampered)))
  let truncated = "csrf_"
  assert_false(csrf_valid(Some(session), Some(truncated)))
  assert_false(csrf_valid(Some(session), None))
  assert_false(csrf_valid(None, Some(session.csrf_token)))
}

///|
test "verify_signed_cookie_value keeps round-tripping with constant-time check" {
  let signed = sign_cookie_value("session", "user-42", "secret-key-base")
  match verify_signed_cookie_value("session", signed, "secret-key-base") {
    Some(value) => assert_eq(value, "user-42")
    None => assert_true(false)
  }
  match verify_signed_cookie_value("session", signed, "wrong-secret") {
    Some(_) => assert_true(false)
    None => assert_true(true)
  }
  let tampered = signed + "x"
  match verify_signed_cookie_value("session", tampered, "secret-key-base") {
    Some(_) => assert_true(false)
    None => assert_true(true)
  }
}
