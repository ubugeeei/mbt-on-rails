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
