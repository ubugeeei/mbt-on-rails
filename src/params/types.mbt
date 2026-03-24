///|
/// Wraps the flat request parameters collected from route, query, or forms.
pub struct Parameters {
  values : Array[(String, String)]
}

///|
/// Stores the filtered parameters produced by a Strong Parameters-style pass.
pub struct PermittedParams {
  scope : String?
  values : Array[(String, String)]
  missing : Array[String]
  rejected : Array[String]
}

///|
/// Builds a `Parameters` value from raw entries.
pub fn params(values : Array[(String, String)]) -> Parameters {
  { values: @support.clone_array(values) }
}

///|
/// Merges route, query, and form parameters into one value.
pub fn merge_params(
  route : Array[(String, String)],
  query : Array[(String, String)],
  form : Array[(String, String)],
) -> Parameters {
  params(@support.append_entries(@support.append_entries(route, query), form))
}

///|
/// Looks up one parameter by key.
pub fn param_value(parameters : Parameters, key : String) -> String? {
  @support.find_entry(parameters.values, key)
}

///|
/// Extracts a dotted scope such as `post.title` and strips the scope prefix.
pub fn require_scope(parameters : Parameters, scope : String) -> Parameters? {
  let scoped = extract_scope_entries(parameters.values, scope)
  if scoped.is_empty() {
    None
  } else {
    Some(params(scoped))
  }
}
