///|
/// Escapes text destined for HTML element content.
///
/// This is the same five-character escape as `escape_html`, named to
/// make the calling context explicit so call sites self-document the
/// rules they are following.
pub fn escape_html_text(source : String) -> String {
  escape_html(source)
}

///|
/// Escapes text destined for the value of a quoted HTML attribute.
///
/// Adds an escape for backtick (`) on top of the normal HTML escapes
/// so legacy Internet Explorer parsers cannot read the attribute as an
/// unquoted value. Always wrap the result in straight double quotes.
pub fn escape_html_attribute(source : String) -> String {
  let sb = StringBuilder::new()
  for ch in source {
    match ch {
      '&' => sb.write_string("&amp;")
      '<' => sb.write_string("&lt;")
      '>' => sb.write_string("&gt;")
      '"' => sb.write_string("&quot;")
      '\'' => sb.write_string("&#39;")
      '`' => sb.write_string("&#96;")
      _ => sb.write_char(ch)
    }
  }
  sb.to_string()
}

///|
/// Escapes a string for embedding inside a JavaScript string literal.
///
/// Escapes the characters that close out of a string (`"`, `'`,
/// backslash) plus the angle brackets and ampersand (so the result is
/// safe even when the surrounding `<script>` is parsed by an HTML
/// parser), plus the line / paragraph separators that JavaScript
/// otherwise treats as line terminators.
pub fn escape_js_string(source : String) -> String {
  let sb = StringBuilder::new()
  for ch in source {
    let code = ch.to_uint()
    if code == 0x5cU {
      sb.write_string("\\\\")
    } else if code == 0x22U {
      sb.write_string("\\\"")
    } else if code == 0x27U {
      sb.write_string("\\'")
    } else if code == 0x3cU {
      sb.write_string("\\u003c")
    } else if code == 0x3eU {
      sb.write_string("\\u003e")
    } else if code == 0x26U {
      sb.write_string("\\u0026")
    } else if code == 0x0aU {
      sb.write_string("\\n")
    } else if code == 0x0dU {
      sb.write_string("\\r")
    } else if code == 0x09U {
      sb.write_string("\\t")
    } else if code == 0x08U {
      sb.write_string("\\b")
    } else if code == 0x0cU {
      sb.write_string("\\f")
    } else if code == 0x00U {
      sb.write_string("\\u0000")
    } else if code == 0x2028U {
      sb.write_string("\\u2028")
    } else if code == 0x2029U {
      sb.write_string("\\u2029")
    } else if code < 0x20U {
      sb.write_string("\\u00")
      sb.write_char(percent_hex_digit((code >> 4) & 0xfU))
      sb.write_char(percent_hex_digit(code & 0xfU))
    } else {
      sb.write_char(ch)
    }
  }
  sb.to_string()
}

///|
/// Percent-encodes a string for use as one component of a URL
/// (the part between two `/`s, a query parameter value, etc.).
///
/// Preserves the RFC 3986 unreserved set (`A-Z`, `a-z`, `0-9`, `-`,
/// `.`, `_`, `~`) and percent-encodes everything else as the UTF-8
/// byte sequence rendered as `%HH` uppercase hex pairs. The
/// implementation deliberately matches the behaviour of JavaScript's
/// `encodeURIComponent` for ASCII inputs.
pub fn escape_url_component(source : String) -> String {
  let sb = StringBuilder::new()
  for ch in source {
    if is_url_unreserved(ch) {
      sb.write_char(ch)
    } else {
      append_percent_encoded_char(sb, ch)
    }
  }
  sb.to_string()
}

///|
/// Escapes a string for use as a CSS identifier or unquoted value.
///
/// Escapes every character outside `[A-Za-z0-9_-]` as `\HH ` (uppercase
/// hex of the Unicode codepoint plus a trailing space, per CSS Syntax
/// Module Level 3). Leading digits and dashes are also escaped so the
/// result is a valid CSS identifier on its own.
pub fn escape_css_value(source : String) -> String {
  let sb = StringBuilder::new()
  let mut first = true
  for ch in source {
    if first && (is_ascii_digit(ch) || ch == '-') {
      append_css_escape(sb, ch)
    } else if is_css_safe(ch) {
      sb.write_char(ch)
    } else {
      append_css_escape(sb, ch)
    }
    first = false
  }
  sb.to_string()
}

///|
fn is_url_unreserved(ch : Char) -> Bool {
  (ch >= 'A' && ch <= 'Z') ||
  (ch >= 'a' && ch <= 'z') ||
  (ch >= '0' && ch <= '9') ||
  ch == '-' ||
  ch == '.' ||
  ch == '_' ||
  ch == '~'
}

///|
fn is_css_safe(ch : Char) -> Bool {
  (ch >= 'A' && ch <= 'Z') ||
  (ch >= 'a' && ch <= 'z') ||
  (ch >= '0' && ch <= '9') ||
  ch == '-' ||
  ch == '_'
}

///|
fn is_ascii_digit(ch : Char) -> Bool {
  ch >= '0' && ch <= '9'
}

///|
fn percent_hex_digit(value : UInt) -> Char {
  if value < 10U {
    ('0'.to_uint() + value).reinterpret_as_int().to_char().unwrap()
  } else {
    ('A'.to_uint() + value - 10U).reinterpret_as_int().to_char().unwrap()
  }
}

///|
/// Appends the UTF-8 percent-encoded form of `ch` to `sb`.
fn append_percent_encoded_char(sb : StringBuilder, ch : Char) -> Unit {
  let bytes : Array[UInt] = []
  encode_char_as_utf8(bytes, ch)
  for value in bytes {
    sb.write_char('%')
    sb.write_char(percent_hex_digit((value >> 4) & 0xfU))
    sb.write_char(percent_hex_digit(value & 0xfU))
  }
}

///|
fn encode_char_as_utf8(out : Array[UInt], ch : Char) -> Unit {
  let code = ch.to_uint()
  if code < 0x80U {
    out.push(code & 0xffU)
  } else if code < 0x800U {
    out.push(0xc0U | (code >> 6))
    out.push(0x80U | (code & 0x3fU))
  } else if code < 0x10000U {
    out.push(0xe0U | (code >> 12))
    out.push(0x80U | ((code >> 6) & 0x3fU))
    out.push(0x80U | (code & 0x3fU))
  } else {
    out.push(0xf0U | (code >> 18))
    out.push(0x80U | ((code >> 12) & 0x3fU))
    out.push(0x80U | ((code >> 6) & 0x3fU))
    out.push(0x80U | (code & 0x3fU))
  }
}

///|
fn append_css_escape(sb : StringBuilder, ch : Char) -> Unit {
  let code = ch.to_uint()
  sb.write_char('\\')
  let mut shift = 28
  let mut started = false
  while shift >= 0 {
    let nibble = (code >> shift) & 0xfU
    if nibble != 0U || started || shift == 0 {
      sb.write_char(percent_hex_digit(nibble))
      started = true
    }
    shift = shift - 4
  }
  sb.write_char(' ')
}
