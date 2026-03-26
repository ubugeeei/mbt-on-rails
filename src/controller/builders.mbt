///|
/// Starts a before-action declaration that applies to every action.
pub fn before_each() -> BeforeAction {
  { action_name: None, requirement: None, allowed_params: [] }
}

///|
/// Starts a before-action declaration for a single action name.
pub fn before_only(action_name : String) -> BeforeAction {
  { action_name: Some(action_name), requirement: None, allowed_params: [] }
}

///|
/// Starts an after-action declaration that applies to every action.
pub fn after_each() -> AfterAction {
  { action_name: None, function_name: "" }
}

///|
/// Starts an after-action declaration for a single action name.
pub fn after_only(action_name : String) -> AfterAction {
  { action_name: Some(action_name), function_name: "" }
}

///|
/// Starts an around-action declaration that applies to every action.
pub fn around_each() -> AroundAction {
  { action_name: None, function_name: "" }
}

///|
/// Starts an around-action declaration for a single action name.
pub fn around_only(action_name : String) -> AroundAction {
  { action_name: Some(action_name), function_name: "" }
}

///|
/// Chainable way to require auth from a before-action.
pub fn BeforeAction::requiring(
  self : BeforeAction,
  requirement : @auth.AuthRequirement,
) -> BeforeAction {
  { ..self, requirement: Some(requirement) }
}

///|
/// Chainable way to assign allowed params to a before-action.
pub fn BeforeAction::permitting(
  self : BeforeAction,
  allowed_params : Array[String],
) -> BeforeAction {
  { ..self, allowed_params: @support.clone_array(allowed_params) }
}

///|
/// Chainable way to assign a function name to an after-action.
pub fn AfterAction::running(
  self : AfterAction,
  function_name : String,
) -> AfterAction {
  { ..self, function_name, }
}

///|
/// Chainable way to assign a function name to an around-action.
pub fn AroundAction::running(
  self : AroundAction,
  function_name : String,
) -> AroundAction {
  { ..self, function_name, }
}

///|
/// Starts an action definition with empty optional metadata.
pub fn action_plan(name : String) -> ActionDefinition {
  {
    name,
    steps: [],
    page_name: None,
    mutation: false,
    allowed_params: [],
    formats: [],
    transactional: false,
  }
}

///|
/// Starts a controller definition with Rails-like defaults.
pub fn controller_named(name : String) -> ControllerDefinition {
  {
    name,
    resource_name: None,
    layout_name: "application",
    before_actions: [],
    after_actions: [],
    around_actions: [],
    actions: [],
  }
}

///|
pub fn ActionDefinition::with_step(
  self : ActionDefinition,
  step : ActionStep,
) -> ActionDefinition {
  let steps = @support.clone_array(self.steps)
  steps.push(step)
  { ..self, steps, }
}

///|
pub fn ActionDefinition::require_auth(
  self : ActionDefinition,
  requirement : @auth.AuthRequirement,
) -> ActionDefinition {
  self.with_step(RequireAuth(requirement))
}

///|
pub fn ActionDefinition::authorize(
  self : ActionDefinition,
  resource : String,
  action_name : String,
) -> ActionDefinition {
  self.with_step(Authorize(resource, action_name))
}

///|
pub fn ActionDefinition::permit_params(
  self : ActionDefinition,
  keys : Array[String],
) -> ActionDefinition {
  self.with_step(PermitParams(keys)).with_allowed_params(keys)
}

///|
pub fn ActionDefinition::load_collection(
  self : ActionDefinition,
  resource : String,
) -> ActionDefinition {
  self.with_step(LoadCollection(resource))
}

///|
pub fn ActionDefinition::load_member(
  self : ActionDefinition,
  resource : String,
) -> ActionDefinition {
  self.with_step(LoadMember(resource))
}

///|
pub fn ActionDefinition::persist_model(
  self : ActionDefinition,
  resource : String,
) -> ActionDefinition {
  self.with_step(PersistModel(resource))
}

///|
pub fn ActionDefinition::render_page(
  self : ActionDefinition,
  page_name : String,
) -> ActionDefinition {
  let action = self.with_step(RenderPage(page_name)).with_page_name(page_name)
  if action.formats.is_empty() {
    action.html()
  } else {
    action
  }
}

///|
pub fn ActionDefinition::redirect_to(
  self : ActionDefinition,
  path : String,
) -> ActionDefinition {
  let action = self.with_step(RedirectTo(path))
  if action.formats.is_empty() {
    action.redirects()
  } else {
    action
  }
}

///|
pub fn ActionDefinition::invoke_server_action(
  self : ActionDefinition,
  name : String,
) -> ActionDefinition {
  self.with_step(InvokeServerAction(name))
}

///|
pub fn ActionDefinition::enqueue_job(
  self : ActionDefinition,
  name : String,
) -> ActionDefinition {
  self.with_step(EnqueueJob(name))
}

///|
pub fn ActionDefinition::deliver_mail(
  self : ActionDefinition,
  name : String,
) -> ActionDefinition {
  self.with_step(DeliverMail(name))
}

///|
pub fn ActionDefinition::touch_cache(
  self : ActionDefinition,
  name : String,
) -> ActionDefinition {
  self.with_step(TouchCache(name))
}

///|
pub fn ActionDefinition::flash(
  self : ActionDefinition,
  key : String,
  value : String,
) -> ActionDefinition {
  self.with_step(SetFlash(key, value))
}

///|
pub fn ActionDefinition::with_page_name(
  self : ActionDefinition,
  page_name : String,
) -> ActionDefinition {
  { ..self, page_name: Some(page_name) }
}

///|
pub fn ActionDefinition::with_allowed_params(
  self : ActionDefinition,
  allowed_params : Array[String],
) -> ActionDefinition {
  { ..self, allowed_params: @support.clone_array(allowed_params) }
}

///|
pub fn ActionDefinition::respond_to(
  self : ActionDefinition,
  format : ResponseFormat,
) -> ActionDefinition {
  let formats = @support.clone_array(self.formats)
  if not(formats.contains(format)) {
    formats.push(format)
  }
  { ..self, formats, }
}

///|
pub fn ActionDefinition::html(self : ActionDefinition) -> ActionDefinition {
  self.respond_to(HtmlFormat)
}

///|
pub fn ActionDefinition::json(self : ActionDefinition) -> ActionDefinition {
  self.respond_to(JsonFormat)
}

///|
pub fn ActionDefinition::turbo_stream(
  self : ActionDefinition,
) -> ActionDefinition {
  self.respond_to(TurboStreamFormat)
}

///|
pub fn ActionDefinition::redirects(self : ActionDefinition) -> ActionDefinition {
  self.respond_to(RedirectFormat)
}

///|
pub fn ActionDefinition::as_mutation(
  self : ActionDefinition,
) -> ActionDefinition {
  { ..self, mutation: true }
}

///|
pub fn ActionDefinition::as_transactional(
  self : ActionDefinition,
) -> ActionDefinition {
  { ..self, transactional: true }
}

///|
pub fn ControllerDefinition::for_resource(
  self : ControllerDefinition,
  resource_name : String,
) -> ControllerDefinition {
  { ..self, resource_name: Some(resource_name) }
}

///|
pub fn ControllerDefinition::with_layout(
  self : ControllerDefinition,
  layout_name : String,
) -> ControllerDefinition {
  { ..self, layout_name, }
}

///|
pub fn ControllerDefinition::with_before_action(
  self : ControllerDefinition,
  before_action : BeforeAction,
) -> ControllerDefinition {
  let before_actions = @support.clone_array(self.before_actions)
  before_actions.push(before_action)
  { ..self, before_actions, }
}

///|
pub fn ControllerDefinition::with_after_action(
  self : ControllerDefinition,
  after_action : AfterAction,
) -> ControllerDefinition {
  let after_actions = @support.clone_array(self.after_actions)
  after_actions.push(after_action)
  { ..self, after_actions, }
}

///|
pub fn ControllerDefinition::with_around_action(
  self : ControllerDefinition,
  around_action : AroundAction,
) -> ControllerDefinition {
  let around_actions = @support.clone_array(self.around_actions)
  around_actions.push(around_action)
  { ..self, around_actions, }
}

///|
pub fn ControllerDefinition::with_action(
  self : ControllerDefinition,
  action : ActionDefinition,
) -> ControllerDefinition {
  let actions = @support.clone_array(self.actions)
  actions.push(action)
  { ..self, actions, }
}
