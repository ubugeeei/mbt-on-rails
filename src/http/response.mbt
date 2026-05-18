///|
/// Builds a plain text response with an explicit content type.
pub fn typed_text_response(
  status : Int,
  content_type : String,
  body : String,
) -> Response {
  response_with_headers(status, [("content-type", content_type)], Text(body))
}

///|
/// Builds a plain text response for an arbitrary status.
pub fn text_response(status : Int, body : String) -> Response {
  typed_text_response(status, "text/plain; charset=utf-8", body)
}

///|
/// Builds a `200 OK` HTML response.
pub fn ok_html(body : String) -> Response {
  response_with_headers(
    200,
    [("content-type", "text/html; charset=utf-8")],
    Html(body),
  )
}

///|
/// Builds a JSON response for an arbitrary status.
pub fn json_response(status : Int, body : String) -> Response {
  response_with_headers(
    status,
    [("content-type", "application/json; charset=utf-8")],
    Json(body),
  )
}

///|
/// Builds a `200 OK` JSON response.
pub fn ok_json(body : String) -> Response {
  json_response(200, body)
}

///|
/// Builds a `201 Created` JSON response.
pub fn created_json(body : String, location? : String? = None) -> Response {
  let response = json_response(201, body)
  match location {
    Some(current) => append_response_headers(response, [("location", current)])
    None => response
  }
}

///|
/// Builds a `202 Accepted` JSON response.
pub fn accepted_json(body : String) -> Response {
  json_response(202, body)
}

///|
/// Builds a `200 OK` plain text response.
pub fn ok_text(body : String) -> Response {
  response_with_headers(
    200,
    [("content-type", "text/plain; charset=utf-8")],
    Text(body),
  )
}

///|
/// Builds a redirect response.
pub fn redirect_response(location : String) -> Response {
  redirect_with_status(302, location)
}

///|
/// Builds a `303 See Other` redirect response.
pub fn see_other_response(location : String) -> Response {
  redirect_with_status(303, location)
}

///|
/// Builds a `404 Not Found` response.
pub fn not_found_response() -> Response {
  response_with_headers(
    404,
    [("content-type", "text/plain; charset=utf-8")],
    Text("Not Found"),
  )
}

///|
/// Builds a `401 Unauthorized` response.
pub fn unauthorized_response(message? : String = "Unauthorized") -> Response {
  text_response(401, message)
}

///|
/// Builds a `403 Forbidden` response.
pub fn forbidden_response(message? : String = "Forbidden") -> Response {
  text_response(403, message)
}

///|
/// Builds a `422 Unprocessable Entity` response.
pub fn unprocessable_entity_response(
  message? : String = "Unprocessable Entity",
) -> Response {
  text_response(422, message)
}

///|
/// Builds a `204 No Content` response.
pub fn no_content_response() -> Response {
  { status: 204, headers: [], body: Empty }
}

///|
/// Returns a response with extra headers appended.
pub fn append_response_headers(
  response : Response,
  extra_headers : Array[(String, String)],
) -> Response {
  let headers : Array[(String, String)] = []
  for header in response.headers {
    headers.push(sanitize_response_header(header))
  }
  for header in extra_headers {
    headers.push(sanitize_response_header(header))
  }
  { status: response.status, headers, body: response.body }
}

///|
/// Returns the same response status and headers with an empty body.
pub fn without_response_body(response : Response) -> Response {
  { status: response.status, headers: response.headers, body: Empty }
}

///|
/// Returns a response with one `Set-Cookie` header appended.
pub fn append_set_cookie(
  response : Response,
  cookie : @auth.AuthCookie,
) -> Response {
  append_response_headers(response, [
    ("set-cookie", @auth.cookie_header(cookie)),
  ])
}

///|
/// Returns a response with many `Set-Cookie` headers appended.
pub fn append_set_cookies(
  response : Response,
  cookies : Array[@auth.AuthCookie],
) -> Response {
  let headers : Array[(String, String)] = []
  for cookie in cookies {
    headers.push(("set-cookie", @auth.cookie_header(cookie)))
  }
  append_response_headers(response, headers)
}

///|
/// Returns the list of all supported HTTP methods.
pub fn all_http_methods() -> Array[HttpMethod] {
  [Get, Post, Put, Patch, Delete, Head, Options]
}

///|
/// Renders a response body to a plain string for tests and CLI output.
pub fn render_response_body(body : ResponseBody) -> String {
  match body {
    Html(content) => content
    Json(content) => content
    Text(content) => content
    Redirect(location) => "Redirecting to " + location
    Empty => ""
  }
}

///|
fn redirect_with_status(status : Int, location : String) -> Response {
  let safe_location = sanitize_header_value(location)
  response_with_headers(
    status,
    [("location", safe_location)],
    Redirect(safe_location),
  )
}

///|
fn response_with_headers(
  status : Int,
  headers : Array[(String, String)],
  body : ResponseBody,
) -> Response {
  let safe_headers : Array[(String, String)] = []
  for header in headers {
    safe_headers.push(sanitize_response_header(header))
  }
  { status, headers: safe_headers, body }
}

///|
fn sanitize_response_header(header : (String, String)) -> (String, String) {
  (sanitize_header_name(header.0), sanitize_header_value(header.1))
}

///|
fn sanitize_header_name(source : String) -> String {
  let builder = StringBuilder::new()
  for ch in source.trim().to_owned() {
    match ch {
      '\n' | '\r' => break
      _ =>
        if is_header_name_char(ch) {
          builder.write_char(ch)
        } else {
          builder.write_char('_')
        }
    }
  }
  let rendered = builder.to_string()
  if rendered.length() == 0 {
    "_"
  } else {
    rendered
  }
}

///|
fn sanitize_header_value(source : String) -> String {
  let builder = StringBuilder::new()
  for ch in source {
    match ch {
      '\n' | '\r' => break
      _ => builder.write_char(ch)
    }
  }
  builder.to_string().trim().to_owned()
}

///|
fn is_header_name_char(ch : Char) -> Bool {
  (ch >= 'A' && ch <= 'Z') ||
  (ch >= 'a' && ch <= 'z') ||
  (ch >= '0' && ch <= '9') ||
  ch == '!' ||
  ch == '#' ||
  ch == '$' ||
  ch == '%' ||
  ch == '&' ||
  ch == '\'' ||
  ch == '*' ||
  ch == '+' ||
  ch == '-' ||
  ch == '.' ||
  ch == '^' ||
  ch == '_' ||
  ch == '`' ||
  ch == '|' ||
  ch == '~'
}
