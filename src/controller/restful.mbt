///|
/// Builds a Rails-like REST controller for a resource.
pub fn restful_controller(
  resource_name : String,
  page_prefix : String,
) -> ControllerDefinition {
  let singular = @support.singularize(resource_name)
  controller(
    @support.classify(resource_name) + "Controller",
    Some(resource_name),
    "application",
    [
      before_action(Some("new"), Some(@auth.auth_required()), []),
      before_action(Some("create"), Some(@auth.auth_required()), [
        "title", "body", "slug",
      ]),
      before_action(Some("edit"), Some(@auth.auth_required()), []),
      before_action(Some("update"), Some(@auth.auth_required()), [
        "title", "body", "slug",
      ]),
      before_action(Some("destroy"), Some(@auth.auth_required()), []),
    ],
    [
      action(
        "index",
        [
          load_collection_step(resource_name),
          render_page_step(page_prefix + "_index"),
        ],
        Some(page_prefix + "_index"),
        false,
        [],
        [html_format(), json_format()],
        false,
      ),
      action(
        "show",
        [
          load_member_step(resource_name),
          render_page_step(page_prefix + "_show"),
        ],
        Some(page_prefix + "_show"),
        false,
        [],
        [html_format(), json_format()],
        false,
      ),
      action(
        "new",
        [
          require_auth(@auth.auth_required()),
          render_page_step(page_prefix + "_new"),
        ],
        Some(page_prefix + "_new"),
        false,
        [],
        [html_format()],
        false,
      ),
      action(
        "create",
        [
          require_auth(@auth.auth_required()),
          authorize_step(resource_name, "create"),
          persist_model_step(resource_name),
          invoke_server_action_step(resource_name + ".create"),
          redirect_to_step("/" + resource_name),
        ],
        None,
        true,
        ["title", "body", "slug"],
        [redirect_format(), json_format()],
        true,
      ),
      action(
        "edit",
        [
          require_auth(@auth.auth_required()),
          load_member_step(resource_name),
          authorize_step(resource_name, "update"),
          render_page_step(page_prefix + "_edit"),
        ],
        Some(page_prefix + "_edit"),
        false,
        [],
        [html_format()],
        false,
      ),
      action(
        "update",
        [
          require_auth(@auth.auth_required()),
          load_member_step(resource_name),
          authorize_step(resource_name, "update"),
          persist_model_step(resource_name),
          invoke_server_action_step(resource_name + ".update"),
          redirect_to_step("/" + resource_name + "/:" + singular + "_id"),
        ],
        None,
        true,
        ["title", "body", "slug"],
        [redirect_format(), json_format()],
        true,
      ),
      action(
        "destroy",
        [
          require_auth(@auth.auth_required()),
          load_member_step(resource_name),
          authorize_step(resource_name, "destroy"),
          invoke_server_action_step(resource_name + ".destroy"),
          redirect_to_step("/" + resource_name),
        ],
        None,
        true,
        [],
        [redirect_format(), json_format()],
        true,
      ),
    ],
  )
}
