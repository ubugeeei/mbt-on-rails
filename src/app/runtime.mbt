///|
/// Handles one incoming request against the app's routes and actions.
pub fn handle_request(
  app : MbtOnRailsApp,
  incoming : @http.Request,
) -> @http.Response {
  let prepared = prepare_request_for_auth(incoming, app.auth)
  let request_result = @middleware.apply_request_middleware(
    app.middlewares,
    prepared,
  )
  let request = prepare_request_for_auth(request_result.0, app.auth)
  match request_result.1 {
    Some(response) =>
      return @middleware.apply_response_middleware(
        app.middlewares,
        request,
        response,
      )
    None => ()
  }

  match find_server_action(app.server_actions, request) {
    Some(action) =>
      return @middleware.apply_response_middleware(
        app.middlewares,
        request,
        server_action_response(app, action, request),
      )
    None => ()
  }

  match @http.recognize(app.routes, request) {
    Some(matched) => {
      match
        route_auth_response(
          app,
          matched.route.controller,
          matched.route.action,
          request,
        ) {
        Some(response) =>
          return @middleware.apply_response_middleware(
            app.middlewares,
            request,
            response,
          )
        None => ()
      }
      match matched.route.page_name {
        Some(page_name) =>
          match find_page(app.pages, page_name) {
            Some(page) => {
              let loader_data : Array[(String, String)] = [
                ("controller", matched.route.controller),
                ("action", matched.route.action),
              ]
              let rendered = @view.render_page(
                page,
                matched.params,
                loader_data,
                app.server_actions,
              )
              @middleware.apply_response_middleware(
                app.middlewares,
                request,
                @http.ok_html(rendered.html),
              )
            }
            None =>
              @middleware.apply_response_middleware(
                app.middlewares,
                request,
                @http.ok_text(
                  matched.route.controller +
                  "#" +
                  matched.route.action +
                  " is configured but has no page module",
                ),
              )
          }
        None =>
          match
            route_action_redirect(
              matched.route.controller,
              matched.route.action,
              matched.params,
            ) {
            Some(location) =>
              @middleware.apply_response_middleware(
                app.middlewares,
                request,
                @http.redirect_response(location),
              )
            None =>
              @middleware.apply_response_middleware(
                app.middlewares,
                request,
                @http.ok_text(
                  "handled " +
                  matched.route.controller +
                  "#" +
                  matched.route.action,
                ),
              )
          }
      }
    }
    None =>
      @middleware.apply_response_middleware(
        app.middlewares,
        request,
        @http.not_found_response(),
      )
  }
}

///|
fn server_action_response(
  app : MbtOnRailsApp,
  action : @view.ServerAction,
  request : @http.Request,
) -> @http.Response {
  match server_action_contract_response(app, action, request) {
    Some(response) => response
    None =>
      @http.ok_json(
        "{" +
        "\"action\": " +
        @support.json_string(action.name) +
        ", \"status\": " +
        @support.json_string("accepted") +
        ", \"body\": " +
        @support.json_string(request.body) +
        "}",
      )
  }
}

///|
fn server_action_contract_response(
  app : MbtOnRailsApp,
  action : @view.ServerAction,
  request : @http.Request,
) -> @http.Response? {
  if request.verb != @http.http_post() {
    return Some(
      @http.append_response_headers(
        @http.text_response(405, "Method Not Allowed"),
        [("allow", "POST")],
      ),
    )
  }
  if action.csrf_protected {
    match request.session_id {
      Some(session_id) =>
        if session_id.trim().to_owned().length() == 0 ||
          !valid_server_action_csrf_token(app, action, request, session_id) {
          return Some(
            @http.unprocessable_entity_response(message="invalid_csrf_token"),
          )
        }
      None =>
        return Some(
          @http.unprocessable_entity_response(message="invalid_csrf_token"),
        )
    }
  }
  let missing = missing_action_inputs(action, request)
  if !missing.is_empty() {
    return Some(
      @http.unprocessable_entity_response(
        message="missing action input: " + missing.join(", "),
      ),
    )
  }
  None
}

///|
fn missing_action_inputs(
  action : @view.ServerAction,
  request : @http.Request,
) -> Array[String] {
  let missing : Array[String] = []
  if action.input_fields.is_empty() {
    return missing
  }
  for field in action.input_fields {
    match @support.find_entry(request.form, field.0) {
      Some(_) => ()
      None => missing.push(field.0)
    }
  }
  missing
}

///|
fn route_auth_response(
  app : MbtOnRailsApp,
  controller_name : String,
  action_name : String,
  request : @http.Request,
) -> @http.Response? {
  match find_controller(app.controllers, controller_name) {
    Some(controller) => {
      for before in controller.before_actions {
        if before_action_applies(before, action_name) {
          match before.requirement {
            Some(requirement) =>
              match auth_requirement_response(requirement, request) {
                Some(response) => return Some(response)
                None => ()
              }
            None => ()
          }
        }
      }
      match @controller.controller_action(controller, action_name) {
        Some(action) =>
          for step in action.steps {
            match step {
              RequireAuth(requirement) =>
                match auth_requirement_response(requirement, request) {
                  Some(response) => return Some(response)
                  None => ()
                }
              _ => ()
            }
          }
        None => ()
      }
    }
    None => ()
  }
  None
}

///|
fn find_controller(
  controllers : Array[@controller.ControllerDefinition],
  name : String,
) -> @controller.ControllerDefinition? {
  for controller in controllers {
    if controller.name == name {
      return Some(controller)
    }
  }
  None
}

///|
fn before_action_applies(
  before : @controller.BeforeAction,
  action_name : String,
) -> Bool {
  match before.action_name {
    Some(expected) => expected == action_name
    None => true
  }
}

///|
fn auth_requirement_response(
  requirement : @auth.AuthRequirement,
  request : @http.Request,
) -> @http.Response? {
  let signed_in = match request.session_id {
    Some(session_id) => session_id.length() > 0
    None => false
  }
  match requirement {
    Public => None
    GuestOnly =>
      if signed_in {
        Some(@http.forbidden_response(message="Already authenticated"))
      } else {
        None
      }
    Authenticated =>
      if signed_in {
        None
      } else {
        Some(@http.unauthorized_response(message="Authentication required"))
      }
    Role(_) =>
      if signed_in {
        Some(@http.forbidden_response(message="Authorization required"))
      } else {
        Some(@http.unauthorized_response(message="Authentication required"))
      }
    Permission(_) =>
      if signed_in {
        Some(@http.forbidden_response(message="Authorization required"))
      } else {
        Some(@http.unauthorized_response(message="Authentication required"))
      }
  }
}

///|
/// Looks up a page by route name.
fn find_page(
  pages : Array[@view.PageModule],
  name : String,
) -> @view.PageModule? {
  for page in pages {
    if page.route_name == name {
      return Some(page)
    }
  }
  None
}

///|
/// Looks up a server action by route path.
fn find_server_action(
  actions : Array[@view.ServerAction],
  request : @http.Request,
) -> @view.ServerAction? {
  if request.verb != @http.http_post() {
    return None
  }
  for action in actions {
    if action.route == request.path {
      return Some(action)
    }
  }
  None
}

///|
fn valid_server_action_csrf_token(
  app : MbtOnRailsApp,
  action : @view.ServerAction,
  request : @http.Request,
  session_id : String,
) -> Bool {
  match @http.request_csrf_token(request, app.auth) {
    Some(token) => {
      if token.trim().to_owned().length() == 0 {
        return false
      }
      match
        @auth.verify_signed_cookie_value(
          server_action_csrf_token_name(action),
          token,
          app.auth.secret_key_base,
        ) {
        Some(value) => value == session_id
        None => false
      }
    }
    None => false
  }
}

///|
fn server_action_csrf_token_name(action : @view.ServerAction) -> String {
  "server_action:" + action.name
}

///|
/// Provides demo redirect behavior for non-page controller actions.
fn route_action_redirect(
  controller_name : String,
  action_name : String,
  params : Array[(String, String)],
) -> String? {
  if controller_name == "PostsController" && action_name == "update" {
    match @support.find_entry(params, "id") {
      Some(id) => return Some("/posts/" + id)
      None => ()
    }
  }
  if action_name == "destroy" || action_name == "create" {
    return Some("/")
  }
  None
}
