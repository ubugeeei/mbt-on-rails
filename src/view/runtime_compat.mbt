///|
/// Returns the inferred client module path for a Vapor Moon component.
pub fn client_module_path(component_name : String) -> String {
  "/_vapor_moon/" + sanitize_component_name(component_name) + ".js"
}

///|
/// Returns the stable scoped-style id used by Vapor Moon.
pub fn make_scope_id(component_name : String) -> String {
  "vm-" + @support.hash_string(component_name)
}

///|
/// Renders prop entries using the same scalar JSON rules as Vapor Moon.
pub fn props_to_json(entries : Array[(String, String)]) -> String {
  @support.entries_to_json(entries)
}

///|
/// Scopes CSS selectors to the supplied Vapor Moon scope id.
pub fn scope_css(css : String, scope_id : String) -> String {
  let chunks = css.split("}").map(fn(part) { part.to_string() }).collect()
  let scoped : Array[String] = []
  for chunk in chunks {
    let trimmed = chunk.trim().to_string()
    if trimmed.length() == 0 {
      continue
    }
    match trimmed.find("{") {
      Some(index) => {
        let selector = String::unsafe_substring(trimmed, start=0, end=index)
          .trim()
          .to_string()
        let body = String::unsafe_substring(
            trimmed,
            start=index + 1,
            end=trimmed.length(),
          )
          .trim()
          .to_string()
        if selector.has_prefix("@") {
          scoped.push(selector + " { " + body + " }")
        } else {
          let selectors = selector
            .split(",")
            .map(fn(part) {
              "[data-vm-scope=\"" + scope_id + "\"] " + part.trim().to_string()
            })
            .collect()
          scoped.push(selectors.join(", ") + " { " + body + " }")
        }
      }
      None => scoped.push(trimmed)
    }
  }
  scoped.join("\n")
}

///|
/// Returns a visibility-aware inline style string.
pub fn show_style(visible : Bool, base : String) -> String {
  let base_style = normalize_style(base)
  if visible {
    return base_style
  }
  if base_style.length() == 0 {
    "display: none;"
  } else if base_style.has_suffix(";") {
    base_style + " display: none;"
  } else {
    base_style + "; display: none;"
  }
}

///|
/// Merges a list of class-name fragments into one class attribute string.
pub fn merge_class_names(parts : Array[String]) -> String {
  let merged : Array[String] = []
  for part in parts {
    let trimmed = part.trim().to_string()
    if trimmed.length() > 0 {
      merged.push(trimmed)
    }
  }
  merged.join(" ")
}

///|
/// Merges inline style fragments into one normalized style string.
pub fn merge_styles(parts : Array[String]) -> String {
  let merged : Array[String] = []
  for part in parts {
    let trimmed = normalize_style(part)
    if trimmed.length() == 0 {
      continue
    }
    if trimmed.has_suffix(";") {
      merged.push(trimmed)
    } else {
      merged.push(trimmed + ";")
    }
  }
  merged.join(" ")
}

///|
/// Creates a typed template ref handle.
pub fn[T] use_template_ref(name : String) -> TemplateRef[T] {
  { name, phantom: None }
}

///|
/// Returns the ref name from a typed template ref handle.
pub fn[T] TemplateRef::name(self : TemplateRef[T]) -> String {
  self.name
}

///|
/// Returns a stable id fragment compatible with Vapor Moon's runtime helper.
pub fn use_id(component_name : String, index : Int) -> String {
  sanitize_component_name(component_name) + "-id-" + index.to_string()
}

///|
fn sanitize_component_name(component_name : String) -> String {
  let sb = StringBuilder::new()
  for ch in component_name {
    if (ch >= 'a' && ch <= 'z') ||
      (ch >= 'A' && ch <= 'Z') ||
      (ch >= '0' && ch <= '9') ||
      ch == '_' ||
      ch == '-' {
      sb.write_char(ch)
    } else {
      sb.write_char('_')
    }
  }
  sb.to_string() + "-" + @support.hash_string(component_name)
}

///|
fn normalize_style(source : String) -> String {
  source.trim().to_string()
}
