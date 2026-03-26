///|
/// Returns the first request header value matching the supplied name.
pub fn request_header(request : Request, name : String) -> String? {
  let expected = ascii_lowercase(name.trim().to_string())
  for header in request.headers {
    if ascii_lowercase(header.0.trim().to_string()) == expected {
      return Some(header.1)
    }
  }
  None
}

///|
/// Returns the flat cookie jar attached to one request.
pub fn request_cookies(request : Request) -> Array[(String, String)] {
  let cookies : Array[(String, String)] = []
  for header in request.headers {
    if ascii_lowercase(header.0.trim().to_string()) != "cookie" {
      continue
    }
    for entry in @auth.parse_cookie_header(header.1) {
      cookies.push(entry)
    }
  }
  cookies
}

///|
/// Returns one cookie value by name from the request.
pub fn request_cookie(request : Request, name : String) -> String? {
  @auth.find_cookie(request_cookies(request), name)
}

///|
/// Returns the verified value of one signed cookie.
pub fn signed_request_cookie(
  request : Request,
  name : String,
  secret : String,
) -> String? {
  match request_cookie(request, name) {
    Some(value) => @auth.verify_signed_cookie_value(name, value, secret)
    None => None
  }
}

///|
/// Returns the session identifier encoded in one request for the given store.
pub fn request_session_id(
  request : Request,
  store : @auth.SessionStore,
) -> String? {
  if store.key.length() == 0 {
    return None
  }
  match request_cookie(request, store.key) {
    Some(value) =>
      if store.signed {
        match store.signing_secret {
          Some(secret) =>
            @auth.verify_signed_cookie_value(store.key, value, secret)
          None => Some(value)
        }
      } else {
        Some(value)
      }
    None => None
  }
}

///|
/// Returns the request CSRF token from headers first, then form data.
pub fn request_csrf_token(
  request : Request,
  config : @auth.AuthConfig,
) -> String? {
  match request_header(request, config.csrf_header) {
    Some(token) => Some(token)
    None => @support.find_entry(request.form, "authenticity_token")
  }
}

///|
/// Returns a copy of the request with an explicit session id attached.
pub fn Request::with_session_id(
  self : Request,
  session_id : String?,
) -> Request {
  { ..self, session_id, }
}

///|
/// Fills `session_id` from the request cookies when it is not already set.
#label_migration(store, allow_positional=true)
pub fn with_request_session(
  request : Request,
  store~ : @auth.SessionStore,
  fallback_store? : @auth.SessionStore? = None,
) -> Request {
  match request.session_id {
    Some(_) => request
    None =>
      match request_session_id(request, store) {
        Some(session_id) => request.with_session_id(Some(session_id))
        None =>
          match fallback_store {
            Some(next_store) =>
              request.with_session_id(request_session_id(request, next_store))
            None => request
          }
      }
  }
}

///|
fn ascii_lowercase(source : String) -> String {
  let builder = StringBuilder::new()
  for ch in source {
    if ch >= 'A' && ch <= 'Z' {
      match (ch.to_int() + 32).to_char() {
        Some(lower) => builder.write_char(lower)
        None => builder.write_char(ch)
      }
    } else {
      builder.write_char(ch)
    }
  }
  builder.to_string()
}
