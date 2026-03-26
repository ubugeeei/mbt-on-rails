///|
/// Renders one void HTML tag with escaped attributes.
pub fn tag(name~ : String, attrs? : Array[(String, String)] = []) -> String {
  "<" + @support.escape_html(name) + render_html_attrs(attrs) + ">"
}

///|
/// Renders one HTML tag with escaped attributes and content.
pub fn content_tag(
  name~ : String,
  content~ : String,
  attrs? : Array[(String, String)] = [],
  escape? : Bool = true,
) -> String {
  let body = if escape { @support.escape_html(content) } else { content }
  "<" +
  @support.escape_html(name) +
  render_html_attrs(attrs) +
  ">" +
  body +
  "</" +
  @support.escape_html(name) +
  ">"
}

///|
/// Renders one HTML anchor element.
pub fn link_to(
  label~ : String,
  href~ : String,
  attrs? : Array[(String, String)] = [],
) -> String {
  let final_attrs = @support.clone_array(attrs)
  final_attrs.insert(0, ("href", href))
  content_tag(name="a", content=label, attrs=final_attrs)
}

///|
/// Renders one form-backed button that can override non-GET/POST verbs.
pub fn button_to(
  label~ : String,
  action~ : String,
  http_method? : String = "post",
  attrs? : Array[(String, String)] = [],
  form_attrs? : Array[(String, String)] = [],
) -> String {
  let normalized_method = normalize_html_method(http_method)
  let effective_form_method = if normalized_method == "get" {
    "get"
  } else {
    "post"
  }
  let resolved_form_attrs = @support.clone_array(form_attrs)
  resolved_form_attrs.insert(0, ("method", effective_form_method))
  resolved_form_attrs.insert(0, ("action", action))

  let button_attrs = @support.clone_array(attrs)
  button_attrs.insert(0, ("type", "submit"))

  let parts : Array[String] = []
  if normalized_method != "get" && normalized_method != "post" {
    parts.push(
      tag(name="input", attrs=[
        ("type", "hidden"),
        ("name", "_method"),
        ("value", normalized_method),
      ]),
    )
  }
  parts.push(content_tag(name="button", content=label, attrs=button_attrs))

  content_tag(
    name="form",
    content=safe_join(parts),
    attrs=resolved_form_attrs,
    escape=false,
  )
}

///|
/// Renders one HTML image tag.
pub fn image_tag(
  src~ : String,
  alt? : String = "",
  attrs? : Array[(String, String)] = [],
) -> String {
  let final_attrs = @support.clone_array(attrs)
  final_attrs.insert(0, ("alt", alt))
  final_attrs.insert(0, ("src", src))
  tag(name="img", attrs=final_attrs)
}

///|
/// Builds one DOM id from a record-like name, optional id, and optional prefix.
pub fn dom_id(
  record_name~ : String,
  record_id? : String? = None,
  prefix? : String? = None,
) -> String {
  let base_name = default_dom_token(
    sanitize_dom_token(@support.singularize(record_name)),
    "record",
  )
  let identity = match record_id {
    Some(id) => {
      let token = sanitize_dom_token(id)
      if token.length() == 0 {
        "new_" + base_name
      } else {
        base_name + "_" + token
      }
    }
    None => "new_" + base_name
  }
  match prefix {
    Some(value) => {
      let token = sanitize_dom_token(value)
      if token.length() == 0 {
        identity
      } else {
        token + "_" + identity
      }
    }
    None => identity
  }
}

///|
/// Renders a count plus a singular or plural word form.
pub fn pluralize(
  count : Int,
  singular : String,
  plural? : String? = None,
) -> String {
  let word = if count == 1 {
    singular
  } else {
    match plural {
      Some(value) => value
      None => infer_plural_form(singular)
    }
  }
  count.to_string() + " " + word
}

///|
/// Joins already-rendered HTML fragments without escaping them again.
pub fn safe_join(parts : Array[String], separator? : String = "") -> String {
  parts.join(separator)
}

///|
/// Joins conditionally enabled CSS class names.
pub fn class_names(entries : Array[(String, Bool)]) -> String {
  let parts : Array[String] = []
  for entry in entries {
    let token = entry.0.trim().to_string()
    if entry.1 && token.length() > 0 {
      parts.push(token)
    }
  }
  parts.join(" ")
}

///|
fn render_html_attrs(attrs : Array[(String, String)]) -> String {
  if attrs.is_empty() {
    return ""
  }
  let parts : Array[String] = []
  for attr in attrs {
    parts.push(
      @support.escape_html(attr.0) + "=\"" + @support.escape_html(attr.1) + "\"",
    )
  }
  " " + parts.join(" ")
}

///|
fn normalize_html_method(http_method : String) -> String {
  let normalized = ascii_lowercase(http_method.trim().to_string())
  if normalized.length() == 0 {
    "post"
  } else {
    normalized
  }
}

///|
fn infer_plural_form(singular : String) -> String {
  if singular.has_suffix("ch") ||
    singular.has_suffix("sh") ||
    singular.has_suffix("s") ||
    singular.has_suffix("x") ||
    singular.has_suffix("z") {
    return singular + "es"
  }
  if singular.has_suffix("y") && singular.length() > 1 {
    return String::unsafe_substring(
        singular,
        start=0,
        end=singular.length() - 1,
      ) +
      "ies"
  }
  singular + "s"
}

///|
fn sanitize_dom_token(source : String) -> String {
  let builder = StringBuilder::new()
  let mut wrote_underscore = false
  for ch in source {
    if (ch >= 'a' && ch <= 'z') || (ch >= '0' && ch <= '9') {
      builder.write_char(ch)
      wrote_underscore = false
      continue
    }
    if ch >= 'A' && ch <= 'Z' {
      match (ch.to_int() + 32).to_char() {
        Some(lower) => builder.write_char(lower)
        None => builder.write_char(ch)
      }
      wrote_underscore = false
      continue
    }
    if not(wrote_underscore) {
      builder.write_char('_')
      wrote_underscore = true
    }
  }
  trim_dom_underscores(builder.to_string())
}

///|
fn trim_dom_underscores(source : String) -> String {
  let chars = source.to_array()
  let mut start = 0
  let mut end = chars.length()
  while start < end && chars[start] == '_' {
    start += 1
  }
  while end > start && chars[end - 1] == '_' {
    end -= 1
  }
  if start == 0 && end == chars.length() {
    return source
  }
  String::unsafe_substring(source, start~, end~)
}

///|
fn default_dom_token(value : String, fallback : String) -> String {
  if value.length() == 0 {
    fallback
  } else {
    value
  }
}

///|
fn ascii_lowercase(source : String) -> String {
  let builder = StringBuilder::new()
  for ch in source {
    if ch >= 'A' && ch <= 'Z' {
      match (ch.to_int() + 32).to_char() {
        Some(lower) => builder.write_char(lower)
        None => builder.write_char(ch)
      }
    } else {
      builder.write_char(ch)
    }
  }
  builder.to_string()
}
