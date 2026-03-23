///|
/// Parses a string route pattern into typed route segments.
pub fn parse_route_pattern(source : String) -> RoutePattern {
  let segments : Array[RouteSegment] = []
  for token in @support.split_path(source) {
    segments.push(parse_route_segment(token))
  }
  { raw: @support.normalize_path(source), segments }
}

///|
/// Matches an incoming path against a parsed route pattern.
pub fn match_route(
  pattern : RoutePattern,
  path : String,
) -> Array[(String, String)]? {
  let path_segments = @support.split_path(path)
  let params : Array[(String, String)] = []
  let mut path_index = 0
  let mut consumed_rest = false
  for segment in pattern.segments {
    match segment {
      Static(value) => {
        if path_index >= path_segments.length() ||
          path_segments[path_index] != value {
          return None
        }
        path_index += 1
      }
      Param(name) => {
        if path_index >= path_segments.length() {
          return None
        }
        params.push((name, path_segments[path_index]))
        path_index += 1
      }
      CatchAll(name) => {
        if path_index >= path_segments.length() {
          return None
        }
        let rest : Array[String] = []
        for index in path_index..<path_segments.length() {
          rest.push(path_segments[index])
        }
        params.push((name, @support.join_path_segments(rest)))
        path_index = path_segments.length()
        consumed_rest = true
        break
      }
      OptionalCatchAll(name) => {
        let rest : Array[String] = []
        for index in path_index..<path_segments.length() {
          rest.push(path_segments[index])
        }
        if not(rest.is_empty()) {
          params.push((name, @support.join_path_segments(rest)))
        }
        path_index = path_segments.length()
        consumed_rest = true
        break
      }
    }
  }
  if consumed_rest || path_index == path_segments.length() {
    Some(params)
  } else {
    None
  }
}

///|
/// Rebuilds a concrete path from a route spec and route params.
pub fn build_path(
  route : RouteSpec,
  params : Array[(String, String)],
) -> String {
  let pieces : Array[String] = []
  for segment in route.pattern.segments {
    match segment {
      Static(value) => pieces.push(value)
      Param(name) =>
        match @support.find_entry(params, name) {
          Some(value) => pieces.push(value)
          None => pieces.push(":" + name)
        }
      CatchAll(name) =>
        match @support.find_entry(params, name) {
          Some(value) =>
            for
              item in value
              .split("/")
              .map(fn(part) { part.to_string() })
              .collect() {
              if item.length() > 0 {
                pieces.push(item)
              }
            }
          None => pieces.push("*")
        }
      OptionalCatchAll(name) =>
        match @support.find_entry(params, name) {
          Some(value) =>
            for
              item in value
              .split("/")
              .map(fn(part) { part.to_string() })
              .collect() {
              if item.length() > 0 {
                pieces.push(item)
              }
            }
          None => ()
        }
    }
  }
  if pieces.is_empty() {
    "/"
  } else {
    "/" + pieces.join("/")
  }
}

///|
/// Finds the first route that matches an incoming request.
pub fn recognize(
  routes : Array[RouteSpec],
  incoming : Request,
) -> MatchedRoute? {
  for current in routes {
    if current.verb != incoming.verb {
      continue
    }
    match match_route(current.pattern, incoming.path) {
      Some(params) => return Some({ route: current, params })
      None => ()
    }
  }
  None
}

///|
/// Converts one token from a route pattern into a typed segment.
fn parse_route_segment(token : String) -> RouteSegment {
  if token.has_prefix("[[...") && token.has_suffix("]]") {
    let name = String::unsafe_substring(token, start=5, end=token.length() - 2)
    return OptionalCatchAll(name)
  }
  if token.has_prefix("[...") && token.has_suffix("]") {
    let name = String::unsafe_substring(token, start=4, end=token.length() - 1)
    return CatchAll(name)
  }
  if token.has_prefix("[") && token.has_suffix("]") {
    let name = String::unsafe_substring(token, start=1, end=token.length() - 1)
    return Param(name)
  }
  if token.has_prefix(":") {
    let name = String::unsafe_substring(token, start=1, end=token.length())
    return Param(name)
  }
  if token == "*" {
    return CatchAll("splat")
  }
  Static(token)
}
