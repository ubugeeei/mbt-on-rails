///|
/// Builds a plain text response with an explicit content type.
pub fn typed_text_response(
  status : Int,
  content_type : String,
  body : String,
) -> Response {
  { status, headers: [("content-type", content_type)], body: Text(body) }
}

///|
/// Builds a plain text response for an arbitrary status.
pub fn text_response(status : Int, body : String) -> Response {
  typed_text_response(status, "text/plain; charset=utf-8", body)
}

///|
/// Builds a `200 OK` HTML response.
pub fn ok_html(body : String) -> Response {
  {
    status: 200,
    headers: [("content-type", "text/html; charset=utf-8")],
    body: Html(body),
  }
}

///|
/// Builds a JSON response for an arbitrary status.
pub fn json_response(status : Int, body : String) -> Response {
  {
    status,
    headers: [("content-type", "application/json; charset=utf-8")],
    body: Json(body),
  }
}

///|
/// Builds a `200 OK` JSON response.
pub fn ok_json(body : String) -> Response {
  json_response(200, body)
}

///|
/// Builds a `200 OK` plain text response.
pub fn ok_text(body : String) -> Response {
  {
    status: 200,
    headers: [("content-type", "text/plain; charset=utf-8")],
    body: Text(body),
  }
}

///|
/// Builds a redirect response.
pub fn redirect_response(location : String) -> Response {
  { status: 302, headers: [("location", location)], body: Redirect(location) }
}

///|
/// Builds a `404 Not Found` response.
pub fn not_found_response() -> Response {
  {
    status: 404,
    headers: [("content-type", "text/plain; charset=utf-8")],
    body: Text("Not Found"),
  }
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
  let headers = @support.clone_array(response.headers)
  for header in extra_headers {
    headers.push(header)
  }
  { status: response.status, headers, body: response.body }
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
