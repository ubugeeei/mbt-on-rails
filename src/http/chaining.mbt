///|
/// Chainable alias for `with_only`.
pub fn ResourceOptions::with_only(
  self : ResourceOptions,
  only : Array[String],
) -> ResourceOptions {
  { ..self, only, }
}

///|
/// Chainable alias for `with_member_action`.
pub fn ResourceOptions::with_member_action(
  self : ResourceOptions,
  name : String,
  verb : HttpMethod,
) -> ResourceOptions {
  let member_actions = @support.clone_array(self.member_actions)
  member_actions.push((name, verb))
  { ..self, member_actions, }
}

///|
/// Chainable alias for `with_collection_action`.
pub fn ResourceOptions::with_collection_action(
  self : ResourceOptions,
  name : String,
  verb : HttpMethod,
) -> ResourceOptions {
  let collection_actions = @support.clone_array(self.collection_actions)
  collection_actions.push((name, verb))
  { ..self, collection_actions, }
}

///|
/// Chainable alias for `with_param_name`.
pub fn ResourceOptions::with_param_name(
  self : ResourceOptions,
  param_name : String,
) -> ResourceOptions {
  { ..self, param_name, }
}
