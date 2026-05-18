///|
test "escape_html_text aliases escape_html and covers the canonical five chars" {
  assert_eq(escape_html_text("plain"), "plain")
  assert_eq(escape_html_text("<b>"), "&lt;b&gt;")
  assert_eq(escape_html_text("a&b"), "a&amp;b")
  assert_eq(escape_html_text("\"x\""), "&quot;x&quot;")
  assert_eq(escape_html_text("'x'"), "&#39;x&#39;")
  assert_eq(escape_html_text("plain"), escape_html("plain"))
}

///|
test "escape_html_attribute additionally escapes the backtick" {
  assert_eq(
    escape_html_attribute("javascript:alert(`x`)"),
    "javascript:alert(&#96;x&#96;)",
  )
  assert_eq(
    escape_html_attribute("<onclick=`x`>"),
    "&lt;onclick=&#96;x&#96;&gt;",
  )
  // The five-char escapes still apply.
  assert_eq(escape_html_attribute("a&b"), "a&amp;b")
}

///|
test "escape_js_string escapes quotes, brackets, ampersand and separators" {
  assert_eq(escape_js_string("hello"), "hello")
  assert_eq(escape_js_string("a\"b"), "a\\\"b")
  assert_eq(escape_js_string("a\\b"), "a\\\\b")
  assert_eq(escape_js_string("a'b"), "a\\'b")
  assert_eq(escape_js_string("</script>"), "\\u003c/script\\u003e")
  assert_eq(escape_js_string("a&b"), "a\\u0026b")
  assert_eq(escape_js_string("line\nbreak"), "line\\nbreak")
  assert_eq(escape_js_string("line\rbreak"), "line\\rbreak")
  assert_eq(escape_js_string("tab\there"), "tab\\there")
  assert_eq(escape_js_string("\u{2028}"), "\\u2028")
  assert_eq(escape_js_string("\u{2029}"), "\\u2029")
  assert_eq(escape_js_string("\u{0001}"), "\\u0001")
}

///|
test "escape_url_component encodes everything outside RFC 3986 unreserved" {
  assert_eq(escape_url_component("plain"), "plain")
  assert_eq(escape_url_component("a-b._c~d"), "a-b._c~d")
  assert_eq(escape_url_component("ABCabc012"), "ABCabc012")
  assert_eq(escape_url_component(" "), "%20")
  assert_eq(escape_url_component("&"), "%26")
  assert_eq(escape_url_component("/"), "%2F")
  assert_eq(escape_url_component("?q=1&x=2"), "%3Fq%3D1%26x%3D2")
  assert_eq(escape_url_component("café"), "caf%C3%A9")
}

///|
test "escape_css_value escapes everything outside [A-Za-z0-9_-]" {
  assert_eq(escape_css_value("plain"), "plain")
  assert_eq(escape_css_value("snake_case"), "snake_case")
  assert_eq(escape_css_value("kebab-case"), "kebab-case")
  let escaped_digit = escape_css_value("1starts")
  assert_true(escaped_digit.has_prefix("\\31 "))
  assert_true(escaped_digit.has_suffix("starts"))
  let escaped_dash = escape_css_value("-starts")
  assert_true(escaped_dash.has_prefix("\\2D "))
  let escaped_special = escape_css_value("a;b{c}")
  assert_false(escaped_special.contains(";"))
  assert_false(escaped_special.contains("{"))
  assert_false(escaped_special.contains("}"))
}
