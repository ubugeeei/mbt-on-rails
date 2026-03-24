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
