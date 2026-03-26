///|
/// Renders a human-readable summary of a controller plan.
pub fn controller_summary(controller : ControllerDefinition) -> String {
  let lines : Array[String] = []
  lines.push(controller.name + " [" + controller.layout_name + "]")
  if not(controller.before_actions.is_empty()) {
    let filters : Array[String] = []
    for filter in controller.before_actions {
      let target = match filter.action_name {
        Some(action_name) => action_name
        None => "*"
      }
      let requirement = match filter.requirement {
        Some(req) => @auth.render_auth_requirement(req)
        None => "none"
      }
      filters.push(target + ":" + requirement)
    }
    lines.push("  before: " + filters.join(", "))
  }
  if not(controller.around_actions.is_empty()) {
    let callbacks : Array[String] = []
    for callback in controller.around_actions {
      let target = match callback.action_name {
        Some(action_name) => action_name
        None => "*"
      }
      callbacks.push(target + ":" + callback.function_name)
    }
    lines.push("  around: " + callbacks.join(", "))
  }
  if not(controller.after_actions.is_empty()) {
    let callbacks : Array[String] = []
    for callback in controller.after_actions {
      let target = match callback.action_name {
        Some(action_name) => action_name
        None => "*"
      }
      callbacks.push(target + ":" + callback.function_name)
    }
    lines.push("  after: " + callbacks.join(", "))
  }
  for action in controller.actions {
    let step_labels : Array[String] = []
    for step in action.steps {
      step_labels.push(render_action_step(step))
    }
    let formats : Array[String] = []
    for format in action.formats {
      formats.push(format.to_string())
    }
    let params_label = if action.allowed_params.is_empty() {
      ""
    } else {
      " params(" + action.allowed_params.join(", ") + ")"
    }
    lines.push(
      "  - " +
      action.name +
      ": " +
      step_labels.join(" -> ") +
      " [" +
      formats.join(", ") +
      "]" +
      params_label,
    )
  }
  lines.join("\n")
}

///|
/// Renders one action step in the compact controller summary format.
fn render_action_step(step : ActionStep) -> String {
  match step {
    RequireAuth(requirement) =>
      "auth(" + @auth.render_auth_requirement(requirement) + ")"
    Authorize(resource, action) => "authorize(" + resource + "." + action + ")"
    PermitParams(keys) => "params(" + keys.join(", ") + ")"
    LoadCollection(resource) => "load_collection(" + resource + ")"
    LoadMember(resource) => "load_member(" + resource + ")"
    PersistModel(resource) => "persist(" + resource + ")"
    RenderPage(page_name) => "render(" + page_name + ")"
    RedirectTo(path) => "redirect(" + path + ")"
    InvokeServerAction(name) => "server_action(" + name + ")"
    EnqueueJob(name) => "enqueue(" + name + ")"
    DeliverMail(name) => "mail(" + name + ")"
    TouchCache(name) => "cache(" + name + ")"
    SetFlash(key, value) => "flash(" + key + "=" + value + ")"
  }
}
