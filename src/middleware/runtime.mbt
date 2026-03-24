///|
/// Applies request middleware and returns a possibly-mutated request plus halt.
pub fn apply_request_middleware(
  middlewares : Array[Middleware],
  request : @http.Request,
) -> (@http.Request, @http.Response?) {
  let mut current = request
  for layer in middlewares {
    if not(middleware_matches(layer, current)) {
      continue
    }
    for header in layer.request_headers {
      current = @http.append_request_header(current, header.0, header.1)
    }
    match layer.halt_response {
      Some(response) => return (current, Some(response))
      None => ()
    }
  }
  (current, None)
}

///|
/// Applies response middleware headers to an outgoing response.
pub fn apply_response_middleware(
  middlewares : Array[Middleware],
  request : @http.Request,
  response : @http.Response,
) -> @http.Response {
  let headers : Array[(String, String)] = []
  for layer in middlewares {
    if not(middleware_matches(layer, request)) {
      continue
    }
    for header in layer.response_headers {
      headers.push(header)
    }
  }
  @http.append_response_headers(response, headers)
}

///|
/// Renders one middleware stack in a CLI-friendly format.
pub fn middleware_summary(middlewares : Array[Middleware]) -> String {
  let lines : Array[String] = []
  for layer in middlewares {
    let methods = if layer.methods.is_empty() {
      "*"
    } else {
      layer.methods.map(fn(verb) { verb.to_string() }).join(", ")
    }
    let path = match layer.path_prefix {
      Some(prefix) => prefix
      None => "*"
    }
    let behavior = match layer.halt_response {
      Some(response) => "halt(" + response.status.to_string() + ")"
      None => "pass"
    }
    lines.push(
      layer.name + " methods=" + methods + " path=" + path + " " + behavior,
    )
  }
  lines.join("\n")
}

///|
/// Returns whether one middleware layer applies to a request.
fn middleware_matches(layer : Middleware, request : @http.Request) -> Bool {
  let method_match = layer.methods.is_empty() ||
    layer.methods.contains(request.verb)
  let path_match = match layer.path_prefix {
    Some(prefix) => request.path.has_prefix(@support.normalize_path(prefix))
    None => true
  }
  method_match && path_match
}
