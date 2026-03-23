///|
/// Clones an array so later mutation does not affect the original value.
pub fn[T] clone_array(items : Array[T]) -> Array[T] {
  let copied : Array[T] = []
  for item in items {
    copied.push(item)
  }
  copied
}

///|
/// Concatenates two key-value entry arrays while preserving order.
pub fn append_entries(
  left : Array[(String, String)],
  right : Array[(String, String)],
) -> Array[(String, String)] {
  let entries : Array[(String, String)] = []
  for entry in left {
    entries.push(entry)
  }
  for entry in right {
    entries.push(entry)
  }
  entries
}

///|
/// Removes a query string from a path-like value.
pub fn remove_query_string(path : String) -> String {
  match path.find("?") {
    Some(index) => String::unsafe_substring(path, start=0, end=index)
    None => path
  }
}

///|
/// Normalizes a path to a leading-slash, no-trailing-slash form.
pub fn normalize_path(path : String) -> String {
  let raw = remove_query_string(path).trim().to_string()
  if raw.length() == 0 || raw == "/" {
    return "/"
  }
  let with_leading = if raw.has_prefix("/") { raw } else { "/" + raw }
  if with_leading.length() > 1 && with_leading.has_suffix("/") {
    String::unsafe_substring(
      with_leading,
      start=0,
      end=with_leading.length() - 1,
    )
  } else {
    with_leading
  }
}

///|
/// Splits a normalized path into non-empty segments.
pub fn split_path(path : String) -> Array[String] {
  let normalized = normalize_path(path)
  if normalized == "/" {
    return []
  }
  let trimmed = String::unsafe_substring(
    normalized,
    start=1,
    end=normalized.length(),
  )
  let parts : Array[String] = []
  for part in trimmed.split("/").map(fn(part) { part.to_string() }).collect() {
    let clean = part.trim().to_string()
    if clean.length() > 0 {
      parts.push(clean)
    }
  }
  parts
}

///|
/// Joins path segments without adding a leading slash.
pub fn join_path_segments(parts : Array[String]) -> String {
  if parts.is_empty() {
    ""
  } else {
    parts.join("/")
  }
}

///|
/// Looks up the first value for a given key in an entry array.
pub fn find_entry(entries : Array[(String, String)], key : String) -> String? {
  for entry in entries {
    if entry.0 == key {
      return Some(entry.1)
    }
  }
  None
}

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
/// Returns whether a string can be emitted as a JSON/SQL numeric literal.
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

///|
/// Converts a snake-case or path-like name into a class-style name.
pub fn classify(source : String) -> String {
  let chars = source.to_array()
  let sb = StringBuilder::new()
  let mut upper_next = true
  for ch in chars {
    if ch == '_' || ch == '-' || ch == '/' {
      upper_next = true
      continue
    }
    if upper_next && ch >= 'a' && ch <= 'z' {
      match (ch.to_int() - 32).to_char() {
        Some(upper) => sb.write_char(upper)
        None => sb.write_char(ch)
      }
    } else {
      sb.write_char(ch)
    }
    upper_next = false
  }
  sb.to_string()
}

///|
/// Converts a simple plural resource name into a singular form.
pub fn singularize(source : String) -> String {
  if source.has_suffix("ies") {
    let stem = String::unsafe_substring(
      source,
      start=0,
      end=source.length() - 3,
    )
    return stem + "y"
  }
  if source.has_suffix("s") {
    return String::unsafe_substring(source, start=0, end=source.length() - 1)
  }
  source
}
