///|
/// Handles one request and records Rails-style controller/view notifications.
pub fn handle_request_with_notifications(
  app~ : MbtOnRailsApp,
  incoming~ : @http.Request,
  notifications~ : @support.Notifications,
) -> (@http.Response, @support.Notifications) {
  let prepared = prepare_request_for_auth(incoming, app.auth)
  let started = notifications.instrument(
    name="start_processing.action_controller",
    payload=[
      ("method", http_method_name(prepared.verb)),
      ("path", prepared.path),
    ],
  )
  let request_result = @middleware.apply_request_middleware(
    app.middlewares,
    prepared,
  )
  let request = prepare_request_for_auth(request_result.0, app.auth)
  match request_result.1 {
    Some(response) => {
      let final_response = @middleware.apply_response_middleware(
        app.middlewares,
        request,
        response,
      )
      return (
        final_response,
        started.instrument(
          name="process_action.action_controller",
          payload=controller_payload(
            controller="Middleware",
            action="halt",
            request~,
            response=final_response,
          ),
        ),
      )
    }
    None => ()
  }

  match find_server_action(app.server_actions, request.path) {
    Some(action) =>
      if request.verb == @http.http_post() {
        let response = @middleware.apply_response_middleware(
          app.middlewares,
          request,
          @http.ok_json(
            "{" +
            "\"action\": " +
            @support.json_string(action.name) +
            ", \"status\": " +
            @support.json_string("accepted") +
            ", \"body\": " +
            @support.json_string(request.body) +
            "}",
          ),
        )
        return (
          response,
          started.instrument(
            name="process_action.action_controller",
            payload=controller_payload(
              controller="ServerActionsController",
              action=action.name,
              request~,
              response~,
            ),
          ),
        )
      }
    None => ()
  }

  match @http.recognize(app.routes, request) {
    Some(matched) =>
      match matched.route.page_name {
        Some(page_name) =>
          match find_page(app.pages, page_name) {
            Some(page) => {
              let loader_data : Array[(String, String)] = [
                ("controller", matched.route.controller),
                ("action", matched.route.action),
              ]
              let (rendered, with_render) = @view.render_page_with_notifications(
                page~,
                route_params=matched.params,
                loader_data~,
                actions=app.server_actions,
                notifications=started,
              )
              let response = @middleware.apply_response_middleware(
                app.middlewares,
                request,
                @http.ok_html(rendered.html),
              )
              (
                response,
                with_render.instrument(
                  name="process_action.action_controller",
                  payload=controller_payload(
                    controller=matched.route.controller,
                    action=matched.route.action,
                    request~,
                    response~,
                  ),
                ),
              )
            }
            None => {
              let response = @middleware.apply_response_middleware(
                app.middlewares,
                request,
                @http.ok_text(
                  matched.route.controller +
                  "#" +
                  matched.route.action +
                  " is configured but has no page module",
                ),
              )
              (
                response,
                started.instrument(
                  name="process_action.action_controller",
                  payload=controller_payload(
                    controller=matched.route.controller,
                    action=matched.route.action,
                    request~,
                    response~,
                  ),
                ),
              )
            }
          }
        None =>
          match
            route_action_redirect(
              matched.route.controller,
              matched.route.action,
              matched.params,
            ) {
            Some(location) => {
              let response = @middleware.apply_response_middleware(
                app.middlewares,
                request,
                @http.redirect_response(location),
              )
              (
                response,
                started.instrument(
                  name="process_action.action_controller",
                  payload=controller_payload(
                    controller=matched.route.controller,
                    action=matched.route.action,
                    request~,
                    response~,
                  ),
                ),
              )
            }
            None => {
              let response = @middleware.apply_response_middleware(
                app.middlewares,
                request,
                @http.ok_text(
                  "handled " +
                  matched.route.controller +
                  "#" +
                  matched.route.action,
                ),
              )
              (
                response,
                started.instrument(
                  name="process_action.action_controller",
                  payload=controller_payload(
                    controller=matched.route.controller,
                    action=matched.route.action,
                    request~,
                    response~,
                  ),
                ),
              )
            }
          }
      }
    None => {
      let response = @middleware.apply_response_middleware(
        app.middlewares,
        request,
        @http.not_found_response(),
      )
      (
        response,
        started.instrument(
          name="process_action.action_controller",
          payload=controller_payload(
            controller="Routing",
            action="not_found",
            request~,
            response~,
          ),
        ),
      )
    }
  }
}

///|
fn controller_payload(
  controller~ : String,
  action~ : String,
  request~ : @http.Request,
  response~ : @http.Response,
) -> Array[(String, String)] {
  let payload : Array[(String, String)] = [
    ("controller", controller),
    ("action", action),
    ("method", http_method_name(request.verb)),
    ("path", request.path),
    ("status", response.status.to_string()),
    ("format", response_format_name(response.body)),
  ]
  match request.session_id {
    Some(session_id) => payload.push(("session_id", session_id))
    None => ()
  }
  payload
}

///|
fn http_method_name(verb : @http.HttpMethod) -> String {
  match verb {
    Get => "GET"
    Post => "POST"
    Put => "PUT"
    Patch => "PATCH"
    Delete => "DELETE"
    Head => "HEAD"
    Options => "OPTIONS"
  }
}

///|
fn response_format_name(body : @http.ResponseBody) -> String {
  match body {
    Html(_) => "html"
    Json(_) => "json"
    Text(_) => "text"
    Redirect(_) => "redirect"
    Empty => "empty"
  }
}
