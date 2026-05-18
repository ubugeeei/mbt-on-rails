///|
/// Renders one void HTML tag with escaped attributes.
pub fn tag(name~ : String, attrs? : Array[(String, String)] = []) -> String {
  "<" + safe_html_tag_name(name) + render_html_attrs(attrs) + ">"
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
  let tag_name = safe_html_tag_name(name)
  "<" + tag_name + render_html_attrs(attrs) + ">" + body + "</" + tag_name + ">"
}

///|
/// Renders one HTML anchor element.
pub fn link_to(
  label~ : String,
  href~ : String,
  attrs? : Array[(String, String)] = [],
) -> String {
  let final_attrs = @support.clone_array(attrs)
  final_attrs.insert(0, ("href", sanitize_link_url(href)))
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
  resolved_form_attrs.insert(0, ("action", sanitize_form_action_url(action)))

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
  final_attrs.insert(0, ("src", sanitize_image_src_url(src)))
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
    let attr_name = attr.0
    if is_valid_html_name(attr_name) && is_safe_html_attr_name(attr_name) {
      match sanitize_html_attr_value(attr_name, attr.1) {
        Some(value) =>
          parts.push(
            @support.escape_html(attr_name) +
            "=\"" +
            @support.escape_html(value) +
            "\"",
          )
        None => ()
      }
    }
  }
  if parts.is_empty() {
    return ""
  }
  " " + parts.join(" ")
}

///|
fn render_safe_fallback_html(html : String) -> String {
  @support.escape_html(html)
}

///|
fn sanitize_html_attr_value(name : String, value : String) -> String? {
  let normalized_name = ascii_lowercase(name)
  if normalized_name == "href" || normalized_name == "xlink:href" {
    return Some(sanitize_link_url(value))
  }
  if normalized_name == "action" || normalized_name == "formaction" {
    return Some(sanitize_form_action_url(value))
  }
  if normalized_name == "src" || normalized_name == "poster" {
    return Some(sanitize_image_src_url(value))
  }
  if normalized_name == "srcset" {
    return sanitize_image_srcset(value)
  }
  Some(value)
}

///|
fn is_safe_html_attr_name(name : String) -> Bool {
  let normalized = ascii_lowercase(name)
  if normalized == "srcdoc" {
    return false
  }
  !(normalized.length() > 2 && normalized.has_prefix("on"))
}

///|
fn sanitize_link_url(url : String) -> String {
  let cleaned = clean_url_value(url)
  if is_allowed_link_url(cleaned) {
    cleaned
  } else {
    "#"
  }
}

///|
fn sanitize_form_action_url(url : String) -> String {
  let cleaned = clean_url_value(url)
  if is_allowed_fetch_url(cleaned) {
    cleaned
  } else {
    "#"
  }
}

///|
fn sanitize_image_src_url(url : String) -> String {
  let cleaned = clean_url_value(url)
  if is_allowed_image_url(cleaned) {
    cleaned
  } else {
    "about:blank"
  }
}

///|
fn sanitize_stylesheet_url(url : String) -> String? {
  let cleaned = clean_url_value(url)
  if is_allowed_fetch_url(cleaned) {
    Some(cleaned)
  } else {
    None
  }
}

///|
fn sanitize_script_url(url : String) -> String? {
  let cleaned = clean_url_value(url)
  if is_allowed_fetch_url(cleaned) {
    Some(cleaned)
  } else {
    None
  }
}

///|
fn sanitize_image_srcset(value : String) -> String? {
  let compact = ascii_lowercase(clean_url_value(value))
  if compact.contains("javascript:") ||
    compact.contains("vbscript:") ||
    compact.contains("data:text/html") ||
    compact.contains("data:application/xhtml") ||
    compact.contains("data:image/svg") {
    None
  } else {
    Some(value)
  }
}

///|
fn is_allowed_link_url(url : String) -> Bool {
  if url.length() == 0 {
    return false
  }
  match url_scheme(url) {
    Some(scheme) =>
      scheme == "http" ||
      scheme == "https" ||
      scheme == "mailto" ||
      scheme == "tel"
    None => true
  }
}

///|
fn is_allowed_fetch_url(url : String) -> Bool {
  if url.length() == 0 {
    return false
  }
  match url_scheme(url) {
    Some(scheme) => scheme == "http" || scheme == "https"
    None => true
  }
}

///|
fn is_allowed_image_url(url : String) -> Bool {
  if url.length() == 0 {
    return false
  }
  match url_scheme(url) {
    Some(scheme) =>
      if scheme == "data" {
        is_safe_image_data_url(url)
      } else {
        scheme == "http" || scheme == "https"
      }
    None => true
  }
}

///|
fn is_safe_image_data_url(url : String) -> Bool {
  let normalized = ascii_lowercase(url)
  normalized.has_prefix("data:image/png;") ||
  normalized.has_prefix("data:image/png,") ||
  normalized.has_prefix("data:image/jpeg;") ||
  normalized.has_prefix("data:image/jpeg,") ||
  normalized.has_prefix("data:image/jpg;") ||
  normalized.has_prefix("data:image/jpg,") ||
  normalized.has_prefix("data:image/gif;") ||
  normalized.has_prefix("data:image/gif,") ||
  normalized.has_prefix("data:image/webp;") ||
  normalized.has_prefix("data:image/webp,") ||
  normalized.has_prefix("data:image/avif;") ||
  normalized.has_prefix("data:image/avif,") ||
  normalized.has_prefix("data:image/bmp;") ||
  normalized.has_prefix("data:image/bmp,") ||
  normalized.has_prefix("data:image/x-icon;") ||
  normalized.has_prefix("data:image/x-icon,") ||
  normalized.has_prefix("data:image/vnd.microsoft.icon;") ||
  normalized.has_prefix("data:image/vnd.microsoft.icon,")
}

///|
fn url_scheme(url : String) -> String? {
  let scheme = StringBuilder::new()
  let mut index = 0
  for ch in url {
    if ch == ':' {
      if index == 0 {
        return None
      }
      return Some(ascii_lowercase(scheme.to_string()))
    }
    if ch == '/' || ch == '?' || ch == '#' {
      return None
    }
    let valid = if index == 0 {
      is_ascii_alpha(ch)
    } else {
      is_ascii_alpha(ch) ||
      is_ascii_digit(ch) ||
      ch == '+' ||
      ch == '-' ||
      ch == '.'
    }
    if !valid {
      return None
    }
    scheme.write_char(ch)
    index += 1
  }
  None
}

///|
fn clean_url_value(source : String) -> String {
  let builder = StringBuilder::new()
  for ch in source {
    if ch.to_int() > 0x20 {
      builder.write_char(ch)
    }
  }
  builder.to_string()
}

///|
fn safe_html_tag_name(name : String) -> String {
  if is_valid_html_name(name) {
    name
  } else {
    "span"
  }
}

///|
fn is_valid_html_name(name : String) -> Bool {
  if name.length() == 0 {
    return false
  }
  let mut index = 0
  for ch in name {
    let valid = if index == 0 {
      (ch >= 'A' && ch <= 'Z') ||
      (ch >= 'a' && ch <= 'z') ||
      ch == '_' ||
      ch == ':'
    } else {
      (ch >= 'A' && ch <= 'Z') ||
      (ch >= 'a' && ch <= 'z') ||
      (ch >= '0' && ch <= '9') ||
      ch == '_' ||
      ch == '-' ||
      ch == ':' ||
      ch == '.'
    }
    if !valid {
      return false
    }
    index += 1
  }
  true
}

///|
fn is_ascii_alpha(ch : Char) -> Bool {
  (ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z')
}

///|
fn is_ascii_digit(ch : Char) -> Bool {
  ch >= '0' && ch <= '9'
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
    if !wrote_underscore {
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
