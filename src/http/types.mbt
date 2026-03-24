///|
/// Lists the HTTP verbs supported by the router.
pub enum HttpMethod {
  Get
  Post
  Put
  Patch
  Delete
  Head
  Options
} derive(Eq, Show)

///|
/// Represents one segment in a route pattern.
pub enum RouteSegment {
  Static(String)
  Param(String)
  CatchAll(String)
  OptionalCatchAll(String)
} derive(Eq, Show)

///|
/// Stores the parsed form of a route pattern.
pub struct RoutePattern {
  raw : String
  segments : Array[RouteSegment]
}

///|
/// Represents an incoming HTTP request as the framework sees it.
pub struct Request {
  verb : HttpMethod
  path : String
  headers : Array[(String, String)]
  query : Array[(String, String)]
  form : Array[(String, String)]
  session_id : String?
  body : String
}

///|
/// Describes one route entry in the router table.
pub struct RouteSpec {
  name : String
  verb : HttpMethod
  pattern : RoutePattern
  controller : String
  action : String
  page_name : String?
}

///|
/// Represents a route plus the params captured from a request path.
pub struct MatchedRoute {
  route : RouteSpec
  params : Array[(String, String)]
}

///|
/// Describes the response body variants supported by the framework.
pub enum ResponseBody {
  Html(String)
  Json(String)
  Text(String)
  Redirect(String)
  Empty
}

///|
/// Represents an HTTP response returned by request handling.
pub struct Response {
  status : Int
  headers : Array[(String, String)]
  body : ResponseBody
}

///|
/// Controls how resource routes are generated.
pub struct ResourceOptions {
  only : Array[String]
  page_prefix : String
  param_name : String
  member_actions : Array[(String, HttpMethod)]
  collection_actions : Array[(String, HttpMethod)]
}

///|
/// Returns the `GET` method.
pub fn http_get() -> HttpMethod {
  Get
}

///|
/// Returns the `POST` method.
pub fn http_post() -> HttpMethod {
  Post
}

///|
/// Returns the `PUT` method.
pub fn http_put() -> HttpMethod {
  Put
}

///|
/// Returns the `PATCH` method.
pub fn http_patch() -> HttpMethod {
  Patch
}

///|
/// Returns the `DELETE` method.
pub fn http_delete() -> HttpMethod {
  Delete
}

///|
/// Returns the `HEAD` method.
pub fn http_head() -> HttpMethod {
  Head
}

///|
/// Returns the `OPTIONS` method.
pub fn http_options() -> HttpMethod {
  Options
}

///|
/// Builds a normalized request value from raw request parts.
pub fn request(
  verb : HttpMethod,
  path : String,
  query : Array[(String, String)],
  form : Array[(String, String)],
  session_id : String?,
  body : String,
) -> Request {
  {
    verb,
    path: @support.normalize_path(path),
    headers: [],
    query,
    form,
    session_id,
    body,
  }
}

///|
/// Returns a request with one more header attached.
pub fn append_request_header(
  request : Request,
  key : String,
  value : String,
) -> Request {
  let headers = @support.clone_array(request.headers)
  headers.push((key, value))
  {
    verb: request.verb,
    path: request.path,
    headers,
    query: @support.clone_array(request.query),
    form: @support.clone_array(request.form),
    session_id: request.session_id,
    body: request.body,
  }
}

///|
/// Builds a route spec and parses its route pattern.
pub fn route(
  name : String,
  verb : HttpMethod,
  path : String,
  controller : String,
  action : String,
  page_name : String?,
) -> RouteSpec {
  {
    name,
    verb,
    pattern: parse_route_pattern(path),
    controller,
    action,
    page_name,
  }
}
