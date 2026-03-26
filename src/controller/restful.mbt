///|
/// Builds a Rails-like REST controller for a resource.
pub fn restful_controller(
  resource_name : String,
  page_prefix : String,
) -> ControllerDefinition {
  restful_controller_with_params(resource_name, page_prefix, [
    "title", "body", "slug",
  ])
}

///|
/// Builds a Rails-like REST controller with inferred strong params.
pub fn restful_controller_with_params(
  resource_name : String,
  page_prefix : String,
  permitted_attributes : Array[String],
) -> ControllerDefinition {
  let singular = @support.singularize(resource_name)
  controller_named(@support.classify(resource_name) + "Controller")
  .for_resource(resource_name)
  .with_before_action(before_only("new").requiring(@auth.auth_required()))
  .with_before_action(
    before_only("create")
    .requiring(@auth.auth_required())
    .permitting(permitted_attributes),
  )
  .with_before_action(before_only("edit").requiring(@auth.auth_required()))
  .with_before_action(
    before_only("update")
    .requiring(@auth.auth_required())
    .permitting(permitted_attributes),
  )
  .with_before_action(before_only("destroy").requiring(@auth.auth_required()))
  .with_action(
    action_plan("index")
    .load_collection(resource_name)
    .render_page(page_prefix + "_index")
    .json(),
  )
  .with_action(
    action_plan("show")
    .load_member(resource_name)
    .render_page(page_prefix + "_show")
    .json(),
  )
  .with_action(
    action_plan("new")
    .require_auth(@auth.auth_required())
    .render_page(page_prefix + "_new"),
  )
  .with_action(
    action_plan("create")
    .require_auth(@auth.auth_required())
    .authorize(resource_name, "create")
    .permit_params(permitted_attributes)
    .persist_model(resource_name)
    .invoke_server_action(resource_name + ".create")
    .enqueue_job(resource_name + ".reindex")
    .touch_cache(resource_name)
    .redirect_to("/" + resource_name)
    .json()
    .as_mutation()
    .as_transactional(),
  )
  .with_action(
    action_plan("edit")
    .require_auth(@auth.auth_required())
    .load_member(resource_name)
    .authorize(resource_name, "update")
    .render_page(page_prefix + "_edit"),
  )
  .with_action(
    action_plan("update")
    .require_auth(@auth.auth_required())
    .load_member(resource_name)
    .authorize(resource_name, "update")
    .permit_params(permitted_attributes)
    .persist_model(resource_name)
    .invoke_server_action(resource_name + ".update")
    .enqueue_job(resource_name + ".reindex")
    .touch_cache(resource_name)
    .redirect_to("/" + resource_name + "/:" + singular + "_id")
    .json()
    .as_mutation()
    .as_transactional(),
  )
  .with_action(
    action_plan("destroy")
    .require_auth(@auth.auth_required())
    .load_member(resource_name)
    .authorize(resource_name, "destroy")
    .invoke_server_action(resource_name + ".destroy")
    .touch_cache(resource_name)
    .redirect_to("/" + resource_name)
    .json()
    .as_mutation()
    .as_transactional(),
  )
}
