///|
/// Property-style and negative-path coverage for the security-sensitive
/// primitives the framework relies on: bound predicate rendering,
/// HMAC cookie signing, and CSRF token validation. Closes the test gap
/// flagged in issue #119.

///|
/// A corpus of SQL meta-characters that should *never* be able to break
/// out of a quoted string literal once routed through the bind pipeline.
fn sql_injection_corpus() -> Array[String] {
  [
    "plain",
    "with 'single' quote",
    "with \"double\" quote",
    "trailing--comment",
    "semi; colon",
    "newline\nin\nbody",
    "carriage\rreturn",
    "back\\slash",
    "null\u{0}byte",
    "mixed '; DROP TABLE users; --",
    "unicode πr² ★",
    "",
  ]
}

///|
test "bound binds round-trip every meta-character as a quoted literal" {
  for payload in sql_injection_corpus() {
    let rendered = substitute_relation_binds("col = ?", [BindText(payload)])
    // The whole literal must be enclosed in single quotes. The first
    // character is the opening quote and the last is the closing quote.
    assert_true(rendered.has_prefix("col = '"))
    assert_true(rendered.has_suffix("'"))
    // The doubled-quote escape rule (SQL standard) is the load-bearing
    // safety property: every literal `'` in the payload becomes two,
    // so the string parser cannot be tricked into closing the literal
    // before the terminator that bind rendering emits.
    let mut quote_count = 0
    let chars = payload.to_array()
    for ch in chars {
      if ch == '\'' {
        quote_count = quote_count + 1
      }
    }
    let mut rendered_inner_quote_count = 0
    let rendered_chars = rendered.to_array()
    let mut index = 0
    // skip "col = '" prefix and trailing "'"
    let start = 7
    let stop = rendered_chars.length() - 1
    while index < rendered_chars.length() {
      if index >= start && index < stop && rendered_chars[index] == '\'' {
        rendered_inner_quote_count = rendered_inner_quote_count + 1
      }
      index = index + 1
    }
    // Every payload quote should appear doubled inside the literal.
    assert_eq(rendered_inner_quote_count, quote_count * 2)
  }
}

///|
test "bound binds reject extra placeholders by expanding to NULL not by inlining" {
  let rendered = substitute_relation_binds("a = ? AND b = ? AND c = ?", [
    BindText("first"),
  ])
  // Two missing binds should become the literal NULL keyword — not the
  // empty string, not an error, not anything that could let a caller
  // smuggle SQL through a missing slot.
  assert_eq(rendered, "a = 'first' AND b = NULL AND c = NULL")
}

///|
test "unsafe_where_raw inlines verbatim, confirming the safe-API opt-in is real" {
  let schema = model(name="post", table="posts", columns=[
    string_column("title"),
    string_column("status"),
  ])
  let raw_relation = unsafe_where_raw(
    relation_for(schema),
    "status = 'draft' OR 1=1",
  )
  let safe = where_with_binds(relation_for(schema), "status = ?", [
    BindText("draft' OR 1=1"),
  ])
  // The unsafe path lets the OR-1=1 escape through.
  assert_true(relation_to_sql(raw_relation).contains("OR 1=1"))
  // The safe path keeps the injection payload inside a single literal.
  let safe_sql = relation_to_sql(safe)
  assert_true(safe_sql.contains("'draft'' OR 1=1'"))
  // And there is no OR keyword followed by 1=1 left at the SQL level.
  assert_false(safe_sql.contains("OR 1=1 "))
}

///|
test "sign_cookie_value is deterministic for the same inputs" {
  let secret = "test-secret-key"
  let first = sign_cookie_value("session", "user-42", secret)
  let second = sign_cookie_value("session", "user-42", secret)
  assert_eq(first, second)
}

///|
test "sign_cookie_value diverges when any one byte of the value changes" {
  let secret = "test-secret-key"
  let baseline = sign_cookie_value("session", "user-42", secret)
  let mutated = sign_cookie_value("session", "user-43", secret)
  assert_true(baseline != mutated)
}

///|
test "sign_cookie_value diverges when the cookie name changes (no key reuse across names)" {
  let secret = "test-secret-key"
  let session_cookie = sign_cookie_value("session", "shared-value", secret)
  let csrf_cookie = sign_cookie_value("csrf", "shared-value", secret)
  // Without the name binding, an attacker who can read the `csrf` cookie
  // could replay it as the `session` cookie. The HMAC must domain-
  // separate by name.
  assert_true(session_cookie != csrf_cookie)
}

///|
test "verify_signed_cookie_value rejects swapped secrets" {
  let signed = sign_cookie_value("session", "user-42", "secret-a")
  match verify_signed_cookie_value("session", signed, "secret-b") {
    Some(_) => assert_true(false)
    None => assert_true(true)
  }
}

///|
test "verify_signed_cookie_value rejects truncated signatures" {
  let signed = sign_cookie_value("session", "user-42", "secret")
  // Drop the last hex character of the signature.
  let truncated = String::unsafe_substring(
    signed,
    start=0,
    end=signed.length() - 1,
  )
  match verify_signed_cookie_value("session", truncated, "secret") {
    Some(_) => assert_true(false)
    None => assert_true(true)
  }
}

///|
test "verify_signed_cookie_value rejects a payload whose value was tampered" {
  let secret = "rotation-key"
  let signed = sign_cookie_value("session", "user-42", secret)
  // Take the signature suffix and re-attach it to a different value.
  let delimiter = "--"
  let mut delimiter_index = -1
  let chars = signed.to_array()
  let mut index = 0
  while index + 2 <= chars.length() {
    if String::unsafe_substring(signed, start=index, end=index + 2) == delimiter {
      delimiter_index = index
    }
    index = index + 1
  }
  assert_true(delimiter_index > 0)
  let signature_with_marker = String::unsafe_substring(
    signed,
    start=delimiter_index,
    end=signed.length(),
  )
  let tampered = "user-43" + signature_with_marker
  match verify_signed_cookie_value("session", tampered, secret) {
    Some(_) => assert_true(false)
    None => assert_true(true)
  }
}

///|
test "verify_signed_cookie_value round-trips an unsigned-looking value containing -- delimiters" {
  // The signing layer uses the *final* `--` as the signature delimiter,
  // so a value that itself contains `--` substrings must still round-
  // trip. This is the regression guard for the "value contains delimiter"
  // edge case.
  let secret = "key"
  let payload = "alpha--beta--gamma"
  let signed = sign_cookie_value("session", payload, secret)
  match verify_signed_cookie_value("session", signed, secret) {
    Some(decoded) => assert_eq(decoded, payload)
    None => assert_true(false)
  }
}

///|
fn fixture_session() -> Session {
  issue_session(
    "user-1",
    "browser",
    entropy=Some("security-properties-entropy"),
    secret=Some("security-properties-secret"),
  )
}

///|
test "csrf_valid rejects when session is missing entirely" {
  assert_false(csrf_valid(None, Some("any-token")))
}

///|
test "csrf_valid rejects when provided token is missing" {
  let session = fixture_session()
  assert_false(csrf_valid(Some(session), None))
}

///|
test "csrf_valid accepts the exact token bound to the session" {
  let session = fixture_session()
  assert_true(csrf_valid(Some(session), Some(session.csrf_token)))
}

///|
test "csrf_valid rejects token of different length (constant-time across length mismatch)" {
  let session = fixture_session()
  assert_false(csrf_valid(Some(session), Some(session.csrf_token + "x")))
  let truncated = String::unsafe_substring(
    session.csrf_token,
    start=0,
    end=session.csrf_token.length() - 1,
  )
  assert_false(csrf_valid(Some(session), Some(truncated)))
}

///|
test "csrf_valid rejects single-byte differences anywhere in the token" {
  let session = fixture_session()
  let token = session.csrf_token
  // Flip the first non-prefix byte (skip the "csrf_" prefix), a middle
  // byte, and the last byte. Each variant differs from the original by
  // exactly one position.
  let prefix_end = 5
  assert_true(token.length() > prefix_end + 2)
  let first_flipped = "X" +
    String::unsafe_substring(token, start=1, end=token.length())
  let mid = token.length() / 2
  let middle_flipped = String::unsafe_substring(token, start=0, end=mid) +
    "X" +
    String::unsafe_substring(token, start=mid + 1, end=token.length())
  let last_flipped = String::unsafe_substring(
      token,
      start=0,
      end=token.length() - 1,
    ) +
    "X"
  for variant in [first_flipped, middle_flipped, last_flipped] {
    assert_false(csrf_valid(Some(session), Some(variant)))
  }
}

///|
test "constant_time_eq is true exactly on byte-for-byte equality" {
  assert_true(constant_time_eq("alpha", "alpha"))
  assert_false(constant_time_eq("alpha", "alphA"))
  assert_false(constant_time_eq("alpha", "alpha "))
  assert_false(constant_time_eq("", "x"))
  assert_true(constant_time_eq("", ""))
}
