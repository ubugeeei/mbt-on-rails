///|
/// Selects which `X-Frame-Options` policy to emit.
pub enum FrameOptionsMode {
  FrameDeny
  FrameSameOrigin
} derive(Eq)

///|
/// Returns the `DENY` frame-options mode.
pub fn frame_options_deny() -> FrameOptionsMode {
  FrameDeny
}

///|
/// Returns the `SAMEORIGIN` frame-options mode.
pub fn frame_options_same_origin() -> FrameOptionsMode {
  FrameSameOrigin
}

///|
/// A structured Content-Security-Policy. Directives left empty are
/// omitted entirely from the rendered header.
pub struct ContentSecurityPolicy {
  default_src : Array[String]
  script_src : Array[String]
  style_src : Array[String]
  img_src : Array[String]
  connect_src : Array[String]
  font_src : Array[String]
  frame_ancestors : Array[String]
  object_src : Array[String]
  base_uri : Array[String]
  form_action : Array[String]
}

///|
/// Returns a deny-by-default CSP suitable as a starting point: every
/// directive scoped to `'self'` except for object/frame which are
/// closed entirely.
pub fn strict_content_security_policy() -> ContentSecurityPolicy {
  {
    default_src: ["'self'"],
    script_src: ["'self'"],
    style_src: ["'self'"],
    img_src: ["'self'", "data:"],
    connect_src: ["'self'"],
    font_src: ["'self'"],
    frame_ancestors: ["'none'"],
    object_src: ["'none'"],
    base_uri: ["'self'"],
    form_action: ["'self'"],
  }
}

///|
/// Renders a `ContentSecurityPolicy` as a header value. Empty
/// directives are skipped so the rendered string only contains the
/// directives the caller actually configured.
pub fn content_security_policy_value(policy : ContentSecurityPolicy) -> String {
  let parts : Array[String] = []
  append_csp_directive(parts, "default-src", policy.default_src)
  append_csp_directive(parts, "script-src", policy.script_src)
  append_csp_directive(parts, "style-src", policy.style_src)
  append_csp_directive(parts, "img-src", policy.img_src)
  append_csp_directive(parts, "connect-src", policy.connect_src)
  append_csp_directive(parts, "font-src", policy.font_src)
  append_csp_directive(parts, "frame-ancestors", policy.frame_ancestors)
  append_csp_directive(parts, "object-src", policy.object_src)
  append_csp_directive(parts, "base-uri", policy.base_uri)
  append_csp_directive(parts, "form-action", policy.form_action)
  parts.join("; ")
}

///|
fn append_csp_directive(
  parts : Array[String],
  name : String,
  sources : Array[String],
) -> Unit {
  if sources.is_empty() {
    return
  }
  parts.push(name + " " + sources.join(" "))
}

///|
/// Middleware that emits `X-Content-Type-Options: nosniff` on every
/// response. Cheap and universally safe.
pub fn nosniff_middleware() -> Middleware {
  middleware(
    "nosniff",
    None,
    [],
    [],
    [("x-content-type-options", "nosniff")],
    None,
  )
}

///|
/// Middleware that emits `X-Frame-Options` for clickjacking protection.
pub fn frame_options_middleware(mode : FrameOptionsMode) -> Middleware {
  let value = match mode {
    FrameDeny => "DENY"
    FrameSameOrigin => "SAMEORIGIN"
  }
  middleware(
    "frame-options",
    None,
    [],
    [],
    [("x-frame-options", value)],
    None,
  )
}

///|
/// Middleware that emits a `Referrer-Policy` header.
pub fn referrer_policy_middleware(policy : String) -> Middleware {
  middleware(
    "referrer-policy",
    None,
    [],
    [],
    [("referrer-policy", policy)],
    None,
  )
}

///|
/// Middleware that emits a `Strict-Transport-Security` header.
///
/// Callers are responsible for only mounting this on HTTPS-served
/// applications — emitting HSTS over plain HTTP is a no-op at best
/// and can lock users out of an HTTP-only fallback at worst.
pub fn hsts_middleware(
  max_age : Int,
  include_subdomains : Bool,
  preload : Bool,
) -> Middleware {
  let parts : Array[String] = ["max-age=" + max_age.to_string()]
  if include_subdomains {
    parts.push("includeSubDomains")
  }
  if preload {
    parts.push("preload")
  }
  middleware(
    "hsts",
    None,
    [],
    [],
    [("strict-transport-security", parts.join("; "))],
    None,
  )
}

///|
/// Middleware that emits a `Content-Security-Policy` header from a
/// structured policy.
pub fn content_security_policy_middleware(
  policy : ContentSecurityPolicy,
) -> Middleware {
  middleware(
    "content-security-policy",
    None,
    [],
    [],
    [("content-security-policy", content_security_policy_value(policy))],
    None,
  )
}

///|
/// CORS configuration. A single allowed origin is used as the
/// `Access-Control-Allow-Origin` value; callers that need multiple
/// origins should mount one CORS middleware bundle per origin under
/// distinct `path_prefix` scopes, or echo the request `Origin` themselves
/// in their own application layer.
pub struct CorsConfig {
  allowed_origin : String
  allowed_methods : Array[@http.HttpMethod]
  allowed_headers : Array[String]
  allow_credentials : Bool
  max_age_seconds : Int
}

///|
/// Builds the preflight + response header middleware pair for CORS.
///
/// The first middleware halts any matching `OPTIONS` request with a
/// `204 No Content` and the configured `Access-Control-*` headers.
/// The second middleware adds `Access-Control-Allow-Origin` (plus
/// `-Allow-Credentials` when enabled) to every other matching response.
pub fn cors_middleware(config : CorsConfig) -> Array[Middleware] {
  let methods = if config.allowed_methods.is_empty() {
    ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
  } else {
    let names : Array[String] = []
    for verb in config.allowed_methods {
      names.push(http_method_name(verb))
    }
    names
  }
  let preflight_headers : Array[(String, String)] = [
    ("access-control-allow-origin", config.allowed_origin),
    ("access-control-allow-methods", methods.join(", ")),
    ("access-control-allow-headers", config.allowed_headers.join(", ")),
    ("access-control-max-age", config.max_age_seconds.to_string()),
  ]
  if config.allow_credentials {
    preflight_headers.push(("access-control-allow-credentials", "true"))
  }
  let preflight_response : @http.Response = {
    status: 204,
    headers: preflight_headers,
    body: Empty,
  }
  let preflight_layer = middleware(
    "cors-preflight",
    None,
    [@http.http_options()],
    [],
    [],
    Some(preflight_response),
  )
  let response_headers : Array[(String, String)] = [
    ("access-control-allow-origin", config.allowed_origin),
  ]
  if config.allow_credentials {
    response_headers.push(("access-control-allow-credentials", "true"))
  }
  let response_layer = middleware(
    "cors-response",
    None,
    [],
    [],
    response_headers,
    None,
  )
  [preflight_layer, response_layer]
}

///|
/// Returns the opinionated default bundle of security-header middlewares:
/// nosniff, frame-options DENY, strict referrer policy, CSP scoped to
/// `'self'`, and HSTS with `max-age=63072000; includeSubDomains; preload`.
///
/// Callers are expected to override individual middlewares as needed
/// (for example loosening CSP to allow a specific CDN).
pub fn default_security_headers_bundle() -> Array[Middleware] {
  [
    nosniff_middleware(),
    frame_options_middleware(FrameDeny),
    referrer_policy_middleware("strict-origin-when-cross-origin"),
    content_security_policy_middleware(strict_content_security_policy()),
    hsts_middleware(63072000, true, true),
  ]
}

///|
fn http_method_name(method : @http.HttpMethod) -> String {
  match method {
    Get => "GET"
    Post => "POST"
    Put => "PUT"
    Patch => "PATCH"
    Delete => "DELETE"
    Head => "HEAD"
    Options => "OPTIONS"
  }
}
