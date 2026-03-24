///|
/// Filters a flat parameter set down to the supplied allowed keys.
pub fn permit(
  parameters : Parameters,
  allowed : Array[String],
) -> PermittedParams {
  filter_entries(None, parameters.values, allowed)
}

///|
/// Filters one dotted scope such as `post.title` to the supplied keys.
pub fn permit_scope(
  parameters : Parameters,
  scope : String,
  allowed : Array[String],
) -> PermittedParams {
  filter_entries(
    Some(scope),
    extract_scope_entries(parameters.values, scope),
    allowed,
  )
}

///|
/// Looks up one value from an already-filtered parameter set.
pub fn permitted_value(permitted : PermittedParams, key : String) -> String? {
  @support.find_entry(permitted.values, key)
}

///|
/// Returns the filtered entries ready to feed into model persistence helpers.
pub fn permitted_attributes(
  permitted : PermittedParams,
) -> Array[(String, String)] {
  @support.clone_array(permitted.values)
}

///|
/// Renders the outcome of a parameter-filtering pass for logs or examples.
pub fn permitted_summary(permitted : PermittedParams) -> String {
  let scope = match permitted.scope {
    Some(name) => name
    None => "*"
  }
  let attrs : Array[String] = []
  for entry in permitted.values {
    attrs.push(entry.0 + "=" + entry.1)
  }
  "scope=" +
  scope +
  " permitted=[" +
  attrs.join(", ") +
  "] missing=[" +
  permitted.missing.join(", ") +
  "] rejected=[" +
  permitted.rejected.join(", ") +
  "]"
}

///|
/// Extracts scoped entries such as `post.title` -> `title`.
fn extract_scope_entries(
  entries : Array[(String, String)],
  scope : String,
) -> Array[(String, String)] {
  let scoped : Array[(String, String)] = []
  let prefix = scope + "."
  for entry in entries {
    if entry.0.has_prefix(prefix) {
      scoped.push(
        (
          String::unsafe_substring(
            entry.0,
            start=prefix.length(),
            end=entry.0.length(),
          ),
          entry.1,
        ),
      )
    }
  }
  scoped
}

///|
/// Implements the common filtering logic used by flat and scoped params.
fn filter_entries(
  scope : String?,
  source : Array[(String, String)],
  allowed : Array[String],
) -> PermittedParams {
  let values : Array[(String, String)] = []
  let rejected : Array[String] = []
  for entry in source {
    if allowed.contains(entry.0) {
      values.push(entry)
    } else {
      rejected.push(entry.0)
    }
  }
  let missing : Array[String] = []
  for key in allowed {
    if @support.find_entry(values, key) is None {
      missing.push(key)
    }
  }
  { scope, values, missing, rejected }
}
