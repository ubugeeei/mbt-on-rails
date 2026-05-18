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
///
/// This is **not** cryptographic. Never use it as a MAC, password digest,
/// or signature primitive — callers that need integrity protection must
/// reach for a real keyed construction (see issue #90).
pub fn hash_string(source : String) -> String {
  let mut hash : UInt = 5381
  for ch in source {
    hash = (hash << 5) + hash + ch.to_uint()
  }
  hash.to_string()
}

///|
/// Compares two strings in time independent of how early they differ.
///
/// The walk always covers `max(left.length(), right.length())` characters,
/// XOR-folds every position into a single accumulator, and only checks
/// equality once. A length mismatch is mixed into the accumulator up
/// front so callers cannot probe length through timing either.
///
/// Use this for anything an attacker can submit and observe the outcome
/// of: signed cookie tags, CSRF tokens, password digests, API tokens.
pub fn constant_time_eq(left : String, right : String) -> Bool {
  let left_chars = left.to_array()
  let right_chars = right.to_array()
  let left_length = left_chars.length()
  let right_length = right_chars.length()
  let walk_length = if left_length >= right_length {
    left_length
  } else {
    right_length
  }
  let mut accumulator : UInt = if left_length == right_length { 0 } else { 1 }
  let mut index = 0
  while index < walk_length {
    let left_code : UInt = if index < left_length {
      left_chars[index].to_uint()
    } else {
      0
    }
    let right_code : UInt = if index < right_length {
      right_chars[index].to_uint()
    } else {
      0
    }
    accumulator = accumulator | (left_code ^ right_code)
    index = index + 1
  }
  accumulator == 0
}
