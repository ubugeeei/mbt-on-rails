///|
/// Returns the default RESTful route generation options for a resource.
pub fn default_resource_options(
  resource_name : String,
  page_prefix : String?,
) -> ResourceOptions {
  {
    only: ["index", "show", "new", "create", "edit", "update", "destroy"],
    page_prefix: match page_prefix {
      Some(prefix) => prefix
      None => resource_name
    },
    param_name: "id",
    member_actions: [],
    collection_actions: [],
  }
}

///|
/// Restricts generated routes to the supplied action names.
pub fn with_only(
  options : ResourceOptions,
  only : Array[String],
) -> ResourceOptions {
  { ..options, only, }
}

///|
/// Adds a member route such as `publish` to a resource.
pub fn with_member_action(
  options : ResourceOptions,
  name : String,
  verb : HttpMethod,
) -> ResourceOptions {
  let member_actions = @support.clone_array(options.member_actions)
  member_actions.push((name, verb))
  { ..options, member_actions, }
}

///|
/// Adds a collection route such as `search` to a resource.
pub fn with_collection_action(
  options : ResourceOptions,
  name : String,
  verb : HttpMethod,
) -> ResourceOptions {
  let collection_actions = @support.clone_array(options.collection_actions)
  collection_actions.push((name, verb))
  { ..options, collection_actions, }
}

///|
/// Overrides the parameter name used for member routes.
pub fn with_param_name(
  options : ResourceOptions,
  param_name : String,
) -> ResourceOptions {
  { ..options, param_name, }
}

///|
/// Expands a resource declaration into Rails-like route entries.
pub fn resources(
  resource_name : String,
  controller : String,
  options : ResourceOptions,
) -> Array[RouteSpec] {
  let routes : Array[RouteSpec] = []
  let base_path = "/" + resource_name
  let member_path = base_path + "/[" + options.param_name + "]"
  let page_prefix = options.page_prefix
  if include_action(options.only, "index") {
    routes.push(
      route(
        resource_name + "_index",
        Get,
        base_path,
        controller,
        "index",
        Some(page_prefix + "_index"),
      ),
    )
  }
  if include_action(options.only, "new") {
    routes.push(
      route(
        resource_name + "_new",
        Get,
        base_path + "/new",
        controller,
        "new",
        Some(page_prefix + "_new"),
      ),
    )
  }
  for action in options.collection_actions {
    routes.push(
      route(
        resource_name + "_" + action.0,
        action.1,
        base_path + "/" + action.0,
        controller,
        action.0,
        None,
      ),
    )
  }
  if include_action(options.only, "create") {
    routes.push(
      route(
        resource_name + "_create",
        Post,
        base_path,
        controller,
        "create",
        None,
      ),
    )
  }
  if include_action(options.only, "show") {
    routes.push(
      route(
        resource_name + "_show",
        Get,
        member_path,
        controller,
        "show",
        Some(page_prefix + "_show"),
      ),
    )
  }
  if include_action(options.only, "edit") {
    routes.push(
      route(
        resource_name + "_edit",
        Get,
        member_path + "/edit",
        controller,
        "edit",
        Some(page_prefix + "_edit"),
      ),
    )
  }
  if include_action(options.only, "update") {
    routes.push(
      route(
        resource_name + "_update",
        Patch,
        member_path,
        controller,
        "update",
        None,
      ),
    )
  }
  if include_action(options.only, "destroy") {
    routes.push(
      route(
        resource_name + "_destroy",
        Delete,
        member_path,
        controller,
        "destroy",
        None,
      ),
    )
  }
  for action in options.member_actions {
    routes.push(
      route(
        resource_name + "_" + action.0,
        action.1,
        member_path + "/" + action.0,
        controller,
        action.0,
        None,
      ),
    )
  }
  routes
}

///|
/// Applies a path and name prefix to a route table.
pub fn scope_routes(
  path_prefix : String,
  name_prefix : String,
  routes : Array[RouteSpec],
) -> Array[RouteSpec] {
  let scoped : Array[RouteSpec] = []
  let prefix = @support.normalize_path(path_prefix)
  for current in routes {
    let combined_path = if current.pattern.raw == "/" {
      prefix
    } else if prefix == "/" {
      current.pattern.raw
    } else {
      prefix + current.pattern.raw
    }
    let scoped_name = if name_prefix.length() == 0 {
      current.name
    } else {
      name_prefix + "_" + current.name
    }
    let scoped_page = match current.page_name {
      Some(page_name) => Some(scoped_name + "_" + page_name)
      None => None
    }
    scoped.push(
      route(
        scoped_name,
        current.verb,
        combined_path,
        current.controller,
        current.action,
        scoped_page,
      ),
    )
  }
  scoped
}

///|
/// Applies a namespace to both path and route names.
pub fn namespace_routes(
  scope_name : String,
  routes : Array[RouteSpec],
) -> Array[RouteSpec] {
  let clean = scope_name.trim().to_string()
  if clean.length() == 0 {
    return routes
  }
  let path_prefix = if clean.has_prefix("/") { clean } else { "/" + clean }
  scope_routes(path_prefix, clean.replace(old="/", new="_"), routes)
}

///|
/// Returns whether a named action is included in the resource DSL.
fn include_action(allowed : Array[String], name : String) -> Bool {
  allowed.contains(name)
}
