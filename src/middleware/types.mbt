///|
/// Describes one Rack-style middleware layer.
pub struct Middleware {
  name : String
  path_prefix : String?
  methods : Array[@http.HttpMethod]
  request_headers : Array[(String, String)]
  response_headers : Array[(String, String)]
  halt_response : @http.Response?
}

///|
/// Builds one middleware layer.
pub fn middleware(
  name : String,
  path_prefix : String?,
  methods : Array[@http.HttpMethod],
  request_headers : Array[(String, String)],
  response_headers : Array[(String, String)],
  halt_response : @http.Response?,
) -> Middleware {
  {
    name,
    path_prefix,
    methods,
    request_headers,
    response_headers,
    halt_response,
  }
}

///|
/// Returns middleware with one more request header attached.
pub fn with_request_header(
  current : Middleware,
  key : String,
  value : String,
) -> Middleware {
  let headers = @support.clone_array(current.request_headers)
  headers.push((key, value))
  { ..current, request_headers: headers }
}

///|
/// Returns middleware with one more response header attached.
pub fn with_response_header(
  current : Middleware,
  key : String,
  value : String,
) -> Middleware {
  let headers = @support.clone_array(current.response_headers)
  headers.push((key, value))
  { ..current, response_headers: headers }
}

///|
/// Builds a middleware layer that halts matching requests with plain text.
pub fn halt_with_text(
  name : String,
  path_prefix : String,
  methods : Array[@http.HttpMethod],
  status : Int,
  body : String,
) -> Middleware {
  middleware(
    name,
    Some(path_prefix),
    methods,
    [],
    [],
    Some(@http.text_response(status, body)),
  )
}
