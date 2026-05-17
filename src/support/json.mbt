///|
/// Escapes a plain string as a JSON string literal.
pub fn json_string(source : String) -> String {
  let sb = StringBuilder::new()
  sb.write_char('"')
  for ch in source {
    match ch {
      '"' => sb.write_string("\\\"")
      '\\' => sb.write_string("\\\\")
      '\b' => sb.write_string("\\b")
      '\u{000C}' => sb.write_string("\\f")
      '\n' => sb.write_string("\\n")
      '\r' => sb.write_string("\\r")
      '\t' => sb.write_string("\\t")
      _ => sb.write_char(ch)
    }
  }
  sb.write_char('"')
  sb.to_string()
}

///|
/// Returns whether a string can be emitted as a JSON or SQL numeric literal.
pub fn is_numeric_literal(source : String) -> Bool {
  if source.length() == 0 {
    return false
  }
  let mut index = 0
  let mut int_digits = 0
  let mut frac_digits = 0
  let mut exp_digits = 0
  let mut seen_dot = false
  let mut seen_exp = false
  let mut allow_exp_sign = false
  let mut first_int_digit = '\u{0}'
  for ch in source {
    if index == 0 && ch == '-' {
      index = index + 1
      continue
    }
    if allow_exp_sign && (ch == '+' || ch == '-') {
      allow_exp_sign = false
      index = index + 1
      continue
    }
    allow_exp_sign = false
    if ch >= '0' && ch <= '9' {
      if seen_exp {
        exp_digits = exp_digits + 1
      } else if seen_dot {
        frac_digits = frac_digits + 1
      } else {
        if int_digits == 0 {
          first_int_digit = ch
        }
        int_digits = int_digits + 1
      }
      index = index + 1
      continue
    }
    if ch == '.' && not(seen_dot) && not(seen_exp) && int_digits > 0 {
      seen_dot = true
      index = index + 1
      continue
    }
    if (ch == 'e' || ch == 'E') &&
      not(seen_exp) &&
      int_digits > 0 &&
      (not(seen_dot) || frac_digits > 0) {
      seen_exp = true
      allow_exp_sign = true
      index = index + 1
      continue
    }
    return false
  }
  if allow_exp_sign || int_digits == 0 {
    return false
  }
  if int_digits > 1 && first_int_digit == '0' {
    return false
  }
  if seen_dot && frac_digits == 0 {
    return false
  }
  if seen_exp && exp_digits == 0 {
    return false
  }
  true
}

///|
/// Converts a scalar string into a JSON value literal when possible.
pub fn json_value(source : String) -> String {
  if source == "true" || source == "false" || source == "null" {
    return source
  }
  if is_numeric_literal(source) {
    source
  } else {
    json_string(source)
  }
}

///|
/// Renders a flat entry array as a small JSON object.
pub fn entries_to_json(entries : Array[(String, String)]) -> String {
  if entries.is_empty() {
    return "{}"
  }
  let parts : Array[String] = []
  for entry in entries {
    parts.push(json_string(entry.0) + ": " + json_value(entry.1))
  }
  "{" + parts.join(", ") + "}"
}
