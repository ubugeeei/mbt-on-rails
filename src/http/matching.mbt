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
        if !rest.is_empty() {
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
          Some(value) => pieces.push(percent_encode_path_segment(value))
          None => pieces.push(":" + name)
        }
      CatchAll(name) =>
        match @support.find_entry(params, name) {
          Some(value) =>
            for
              item in value
              .split("/")
              .map(fn(part) { part.to_owned() })
              .collect() {
              if item.length() > 0 {
                pieces.push(percent_encode_path_segment(item))
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
              .map(fn(part) { part.to_owned() })
              .collect() {
              if item.length() > 0 {
                pieces.push(percent_encode_path_segment(item))
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
  match recognize_exact(routes, incoming) {
    Some(matched) => return Some(matched)
    None => ()
  }
  if incoming.verb == Head {
    let get_request = { ..incoming, verb: Get }
    recognize_exact(routes, get_request)
  } else {
    None
  }
}

///|
fn recognize_exact(
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
fn percent_encode_path_segment(value : String) -> String {
  let builder = StringBuilder::new()
  for ch in value {
    if is_unreserved_path_char(ch) {
      builder.write_char(ch)
    } else {
      write_percent_encoded_utf8(builder, ch.to_int())
    }
  }
  builder.to_string()
}

///|
fn write_percent_encoded_utf8(builder : StringBuilder, code : Int) -> Unit {
  if code <= 0x7F {
    write_percent_encoded_byte(builder, code)
  } else if code <= 0x7FF {
    write_percent_encoded_byte(builder, 0xC0 + code / 0x40)
    write_percent_encoded_byte(builder, 0x80 + code % 0x40)
  } else if code <= 0xFFFF {
    write_percent_encoded_byte(builder, 0xE0 + code / 0x1000)
    write_percent_encoded_byte(builder, 0x80 + code / 0x40 % 0x40)
    write_percent_encoded_byte(builder, 0x80 + code % 0x40)
  } else {
    write_percent_encoded_byte(builder, 0xF0 + code / 0x40000)
    write_percent_encoded_byte(builder, 0x80 + code / 0x1000 % 0x40)
    write_percent_encoded_byte(builder, 0x80 + code / 0x40 % 0x40)
    write_percent_encoded_byte(builder, 0x80 + code % 0x40)
  }
}

///|
fn write_percent_encoded_byte(builder : StringBuilder, byte : Int) -> Unit {
  builder.write_char('%')
  builder.write_char(hex_digit(byte / 16))
  builder.write_char(hex_digit(byte % 16))
}

///|
fn hex_digit(value : Int) -> Char {
  if value < 10 {
    ('0'.to_int() + value).to_char().unwrap()
  } else {
    ('A'.to_int() + value - 10).to_char().unwrap()
  }
}

///|
fn is_unreserved_path_char(ch : Char) -> Bool {
  let code = ch.to_int()
  (code >= 'a'.to_int() && code <= 'z'.to_int()) ||
  (code >= 'A'.to_int() && code <= 'Z'.to_int()) ||
  (code >= '0'.to_int() && code <= '9'.to_int()) ||
  ch == '-' ||
  ch == '.' ||
  ch == '_' ||
  ch == '~'
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
