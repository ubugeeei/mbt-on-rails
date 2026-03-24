///|
/// Escapes text for safe inclusion in HTML attributes or nodes.
pub fn escape_html(source : String) -> String {
  let sb = StringBuilder::new()
  for ch in source {
    match ch {
      '&' => sb.write_string("&amp;")
      '<' => sb.write_string("&lt;")
      '>' => sb.write_string("&gt;")
      '"' => sb.write_string("&quot;")
      '\'' => sb.write_string("&#39;")
      _ => sb.write_char(ch)
    }
  }
  sb.to_string()
}

///|
/// Escapes single quotes for SQL string literals.
pub fn escape_sql_string(source : String) -> String {
  let sb = StringBuilder::new()
  for ch in source {
    if ch == '\'' {
      sb.write_string("''")
    } else {
      sb.write_char(ch)
    }
  }
  sb.to_string()
}

///|
/// Converts a scalar string into a SQL literal when possible.
pub fn sql_literal(value : String) -> String {
  if value == "true" {
    return "TRUE"
  }
  if value == "false" {
    return "FALSE"
  }
  if value == "null" {
    return "NULL"
  }
  if is_numeric_literal(value) {
    return value
  }
  "'" + escape_sql_string(value) + "'"
}

///|
/// Produces a small deterministic hash string for demo identifiers.
pub fn hash_string(source : String) -> String {
  let mut hash : UInt = 5381
  for ch in source {
    hash = (hash << 5) + hash + ch.to_uint()
  }
  hash.to_string()
}
