///|
/// Applies request middleware and returns a possibly-mutated request plus halt.
pub fn apply_request_middleware(
  middlewares : Array[Middleware],
  request : @http.Request,
) -> (@http.Request, @http.Response?) {
  let applied = apply_request_middleware_with_reached(middlewares, request)
  (applied.0, applied.1)
}

///|
/// Applies request middleware and returns the layers reached before a halt.
pub fn apply_request_middleware_with_reached(
  middlewares : Array[Middleware],
  request : @http.Request,
) -> (@http.Request, @http.Response?, Array[Middleware]) {
  let mut current = request
  let reached : Array[Middleware] = []
  for layer in middlewares {
    if !middleware_matches(layer, current) {
      continue
    }
    reached.push(layer)
    for header in layer.request_headers {
      current = @http.append_request_header(current, header.0, header.1)
    }
    match layer.halt_response {
      Some(response) => return (current, Some(response), reached)
      None => ()
    }
  }
  (current, None, reached)
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
    if !middleware_matches(layer, request) {
      continue
    }
    for header in layer.response_headers {
      headers.push(header)
    }
  }
  @http.append_response_headers(response, headers)
}

///|
/// Applies response middleware from layers already reached by request handling.
pub fn apply_reached_response_middleware(
  reached_middlewares : Array[Middleware],
  response : @http.Response,
) -> @http.Response {
  let headers : Array[(String, String)] = []
  for layer in reached_middlewares {
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
    Some(prefix) => path_prefix_matches(request.path, prefix)
    None => true
  }
  method_match && path_match
}

///|
fn path_prefix_matches(path : String, prefix : String) -> Bool {
  let normalized_path = @support.normalize_path(path)
  let normalized_prefix = @support.normalize_path(prefix)
  normalized_prefix == "/" ||
  normalized_path == normalized_prefix ||
  normalized_path.has_prefix(normalized_prefix + "/")
}
