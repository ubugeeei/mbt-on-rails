///|
/// Describes the steps a controller action will perform.
pub enum ActionStep {
  RequireAuth(@auth.AuthRequirement)
  Authorize(String, String)
  PermitParams(Array[String])
  LoadCollection(String)
  LoadMember(String)
  PersistModel(String)
  RenderPage(String)
  RedirectTo(String)
  InvokeServerAction(String)
  EnqueueJob(String)
  DeliverMail(String)
  TouchCache(String)
  SetFlash(String, String)
} derive(Show)

///|
/// Lists the response envelopes an action can negotiate.
pub enum ResponseFormat {
  HtmlFormat
  JsonFormat
  TurboStreamFormat
  RedirectFormat
} derive(Eq, Show)

///|
/// Declares a before-action filter for a controller.
pub struct BeforeAction {
  action_name : String?
  requirement : @auth.AuthRequirement?
  allowed_params : Array[String]
}

///|
/// Declares an after-action callback for a controller.
pub struct AfterAction {
  action_name : String?
  function_name : String
}

///|
/// Declares an around-action callback for a controller.
pub struct AroundAction {
  action_name : String?
  function_name : String
}

///|
/// Describes one controller action and its execution plan.
pub struct ActionDefinition {
  name : String
  steps : Array[ActionStep]
  page_name : String?
  mutation : Bool
  allowed_params : Array[String]
  formats : Array[ResponseFormat]
  transactional : Bool
}

///|
/// Collects the actions and filters that form one controller.
pub struct ControllerDefinition {
  name : String
  resource_name : String?
  layout_name : String
  before_actions : Array[BeforeAction]
  after_actions : Array[AfterAction]
  around_actions : Array[AroundAction]
  actions : Array[ActionDefinition]
}

///|
/// Builds a `BeforeAction` filter declaration.
pub fn before_action(
  action_name : String?,
  requirement : @auth.AuthRequirement?,
  allowed_params : Array[String],
) -> BeforeAction {
  { action_name, requirement, allowed_params }
}

///|
/// Builds an `AfterAction` callback declaration.
pub fn after_action(
  action_name : String?,
  function_name : String,
) -> AfterAction {
  { action_name, function_name }
}

///|
/// Builds an `AroundAction` callback declaration.
pub fn around_action(
  action_name : String?,
  function_name : String,
) -> AroundAction {
  { action_name, function_name }
}

///|
/// Builds an `ActionDefinition`.
pub fn action(
  name : String,
  steps : Array[ActionStep],
  page_name : String?,
  mutation : Bool,
  allowed_params : Array[String],
  formats : Array[ResponseFormat],
  transactional : Bool,
) -> ActionDefinition {
  { name, steps, page_name, mutation, allowed_params, formats, transactional }
}

///|
/// Builds a `ControllerDefinition`.
pub fn controller(
  name : String,
  resource_name : String?,
  layout_name : String,
  before_actions : Array[BeforeAction],
  after_actions : Array[AfterAction],
  around_actions : Array[AroundAction],
  actions : Array[ActionDefinition],
) -> ControllerDefinition {
  {
    name,
    resource_name,
    layout_name,
    before_actions,
    after_actions,
    around_actions,
    actions,
  }
}

///|
/// Adds a flash write to an action plan.
pub fn flash(key : String, value : String) -> ActionStep {
  SetFlash(key, value)
}

///|
/// Requires a request identity to satisfy an auth requirement.
pub fn require_auth(requirement : @auth.AuthRequirement) -> ActionStep {
  RequireAuth(requirement)
}

///|
/// Adds a resource/action authorization check to an action plan.
pub fn authorize_step(resource : String, action : String) -> ActionStep {
  Authorize(resource, action)
}

///|
/// Adds a strong-parameters filtering step to an action plan.
pub fn permit_params_step(keys : Array[String]) -> ActionStep {
  PermitParams(keys)
}

///|
/// Adds a collection load step to an action plan.
pub fn load_collection_step(resource : String) -> ActionStep {
  LoadCollection(resource)
}

///|
/// Adds a member load step to an action plan.
pub fn load_member_step(resource : String) -> ActionStep {
  LoadMember(resource)
}

///|
/// Adds a persistence step to an action plan.
pub fn persist_model_step(resource : String) -> ActionStep {
  PersistModel(resource)
}

///|
/// Adds a page render step to an action plan.
pub fn render_page_step(page_name : String) -> ActionStep {
  RenderPage(page_name)
}

///|
/// Adds a redirect step to an action plan.
pub fn redirect_to_step(path : String) -> ActionStep {
  RedirectTo(path)
}

///|
/// Adds a server action invocation step to an action plan.
pub fn invoke_server_action_step(name : String) -> ActionStep {
  InvokeServerAction(name)
}

///|
/// Adds a background job enqueue step to an action plan.
pub fn enqueue_job_step(name : String) -> ActionStep {
  EnqueueJob(name)
}

///|
/// Adds a mail delivery step to an action plan.
pub fn deliver_mail_step(name : String) -> ActionStep {
  DeliverMail(name)
}

///|
/// Adds a cache invalidation step to an action plan.
pub fn touch_cache_step(name : String) -> ActionStep {
  TouchCache(name)
}

///|
/// Returns the HTML response format.
pub fn html_format() -> ResponseFormat {
  HtmlFormat
}

///|
/// Returns the JSON response format.
pub fn json_format() -> ResponseFormat {
  JsonFormat
}

///|
/// Returns the Turbo Stream response format.
pub fn turbo_stream_format() -> ResponseFormat {
  TurboStreamFormat
}

///|
/// Returns the redirect response format.
pub fn redirect_format() -> ResponseFormat {
  RedirectFormat
}

///|
/// Finds one action definition by name.
pub fn controller_action(
  controller : ControllerDefinition,
  action_name : String,
) -> ActionDefinition? {
  for action in controller.actions {
    if action.name == action_name {
      return Some(action)
    }
  }
  None
}
