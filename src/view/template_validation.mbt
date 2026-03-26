///|
/// Extracts explicit component imports from one `.mbtv` source string.
pub fn template_component_imports(source : String) -> Array[String] {
  let script = extract_between(source, "<script setup>", "</script>")
  let imports : Array[String] = []
  for line_view in script.split("\n") {
    let line = line_view.trim().to_string()
    if line.contains("component ") {
      let name = parse_component_name_after(line, "component ")
      if name.length() > 0 && not(imports.contains(name)) {
        imports.push(name)
      }
    }
  }
  imports
}

///|
/// Extracts capitalized component tags used from one `.mbtv` source string.
pub fn template_component_usages(source : String) -> Array[String] {
  let template = extract_between(source, "<template>", "</template>")
  let usages : Array[String] = []
  let chars = template.to_array()
  for i = 0; i < chars.length() - 1; i = i + 1 {
    if chars[i] == '<' && chars[i + 1] != '/' && is_upper_alpha(chars[i + 1]) {
      let name = collect_component_name(chars, i + 1)
      if name.length() > 0 && not(usages.contains(name)) {
        usages.push(name)
      }
    }
  }
  usages
}

///|
/// Validates one `.mbtv` source string and returns missing/unused component imports.
pub fn validate_template_component_imports(
  path : String,
  source : String,
) -> Array[String] {
  let imports = template_component_imports(source)
  let usages = template_component_usages(source)
  let errors : Array[String] = []
  for usage in usages {
    if not(imports.contains(usage)) {
      errors.push(path + ": missing component import for <" + usage + ">")
    }
  }
  for imported in imports {
    if not(usages.contains(imported)) {
      errors.push(path + ": unused component import " + imported)
    }
  }
  errors
}

///|
fn extract_between(source : String, start : String, end_ : String) -> String {
  let parts : Array[String] = source
    .split(start)
    .map(fn(part) { part.to_string() })
    .collect()
  if parts.length() < 2 {
    return ""
  }
  let tail = parts[1]
  let inner : Array[String] = tail
    .split(end_)
    .map(fn(part) { part.to_string() })
    .collect()
  if inner.is_empty() {
    ""
  } else {
    inner[0]
  }
}

///|
fn parse_component_name_after(line : String, marker : String) -> String {
  let parts : Array[String] = line
    .split(marker)
    .map(fn(part) { part.to_string() })
    .collect()
  if parts.length() < 2 {
    return ""
  }
  collect_component_name(parts[1].to_array(), 0)
}

///|
fn collect_component_name(chars : Array[Char], start : Int) -> String {
  let sb = StringBuilder::new()
  for i = start; i < chars.length(); i = i + 1 {
    let ch = chars[i]
    if is_component_char(ch) {
      sb.write_char(ch)
    } else {
      break
    }
  }
  sb.to_string()
}

///|
fn is_upper_alpha(ch : Char) -> Bool {
  ch >= 'A' && ch <= 'Z'
}

///|
fn is_component_char(ch : Char) -> Bool {
  (ch >= 'A' && ch <= 'Z') ||
  (ch >= 'a' && ch <= 'z') ||
  (ch >= '0' && ch <= '9')
}
