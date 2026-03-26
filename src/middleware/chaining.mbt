///|
/// Chainable alias for `with_request_header`.
pub fn Middleware::with_request_header(
  self : Middleware,
  key : String,
  value : String,
) -> Middleware {
  let headers = @support.clone_array(self.request_headers)
  headers.push((key, value))
  { ..self, request_headers: headers }
}

///|
/// Chainable alias for `with_response_header`.
pub fn Middleware::with_response_header(
  self : Middleware,
  key : String,
  value : String,
) -> Middleware {
  let headers = @support.clone_array(self.response_headers)
  headers.push((key, value))
  { ..self, response_headers: headers }
}
