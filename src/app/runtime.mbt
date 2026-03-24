///|
/// Handles one incoming request against the app's routes and actions.
pub fn handle_request(
  app : MbtOnRailsApp,
  incoming : @http.Request,
) -> @http.Response {
  let request_result = @middleware.apply_request_middleware(
    app.middlewares,
    incoming,
  )
  let request = request_result.0
  match request_result.1 {
    Some(response) =>
      return @middleware.apply_response_middleware(
        app.middlewares,
        request,
        response,
      )
    None => ()
  }

  match find_server_action(app.server_actions, request.path) {
    Some(action) =>
      if request.verb == @http.http_post() {
        return @middleware.apply_response_middleware(
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
    None =>
      @middleware.apply_response_middleware(
        app.middlewares,
        request,
        @http.not_found_response(),
      )
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
  route : String,
) -> @view.ServerAction? {
  for action in actions {
    if action.route == route {
      return Some(action)
    }
  }
  None
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
