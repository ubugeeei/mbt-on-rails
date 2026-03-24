///|
/// Escapes a plain string as a JSON string literal.
pub fn json_string(source : String) -> String {
  let sb = StringBuilder::new()
  sb.write_char('"')
  for ch in source {
    match ch {
      '"' => sb.write_string("\\\"")
      '\\' => sb.write_string("\\\\")
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
  for ch in source {
    if not((ch >= '0' && ch <= '9') || ch == '.' || ch == '-') {
      return false
    }
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
