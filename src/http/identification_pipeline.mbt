///|
/// Resolves the request id for `request`, adds it as `header_name` on
/// the returned request, and returns both the rewritten request and the
/// id so the caller can mirror the value onto the eventual response.
///
/// The id is sourced from the existing header when present (passing
/// through `resolve_request_id`'s sanitisation) and falls back to
/// `fallback_id` — the caller is expected to mint a fresh random value
/// at the boundary so every request has a stable correlation id.
pub fn tag_request_with_id(
  request : Request,
  header_name : String,
  fallback_id : String,
) -> (Request, String) {
  let id = resolve_request_id(request, header_name, fallback_id)
  (append_request_header(request, header_name, id), id)
}

///|
/// Adds `header_name: id` to `response`, normally used to mirror the
/// resolved request id onto the outgoing response so clients can
/// correlate their request with this server's logs.
pub fn tag_response_with_request_id(
  response : Response,
  header_name : String,
  id : String,
) -> Response {
  append_response_headers(response, [(header_name, id)])
}

///|
/// Resolves trusted-proxy-aware client metadata for `request` and
/// surfaces it on the rewritten request as discoverable headers.
///
/// Reads `forwarded_for_header`, `forwarded_proto_header` and
/// `forwarded_host_header` from `request`, walks each through the
/// trusted-proxy aware helpers, and writes the resolved value back
/// onto the request as:
///
/// - `x-resolved-client-ip`
/// - `x-resolved-client-proto`
/// - `x-resolved-client-host`
///
/// Handlers read these via `request_header(request, "x-resolved-client-ip")`
/// without needing to know the upstream Forwarded-* dialect. Missing
/// or untrusted headers are simply skipped so applications behind no
/// proxy at all continue to work unchanged.
pub fn apply_trusted_proxy(
  request : Request,
  trusted_proxies : Array[String],
  forwarded_for_header? : String = "x-forwarded-for",
  forwarded_proto_header? : String = "x-forwarded-proto",
  forwarded_host_header? : String = "x-forwarded-host",
) -> Request {
  let mut current = request
  match request_header(current, forwarded_for_header) {
    Some(raw) =>
      match parse_forwarded_for(raw, trusted_proxies) {
        Some(ip) =>
          current = append_request_header(current, "x-resolved-client-ip", ip)
        None => ()
      }
    None => ()
  }
  match request_header(current, forwarded_proto_header) {
    Some(raw) =>
      match parse_forwarded_leftmost(raw) {
        Some(proto) =>
          current = append_request_header(
            current, "x-resolved-client-proto", proto,
          )
        None => ()
      }
    None => ()
  }
  match request_header(current, forwarded_host_header) {
    Some(raw) =>
      match parse_forwarded_leftmost(raw) {
        Some(host) =>
          current = append_request_header(
            current, "x-resolved-client-host", host,
          )
        None => ()
      }
    None => ()
  }
  current
}

///|
/// Returns the trusted-proxy-resolved client IP, or `None` if no
/// trusted-proxy pipeline has been applied to this request.
pub fn resolved_client_ip(request : Request) -> String? {
  request_header(request, "x-resolved-client-ip")
}

///|
/// Returns the trusted-proxy-resolved client scheme, or `None` if no
/// trusted-proxy pipeline has been applied to this request.
pub fn resolved_client_proto(request : Request) -> String? {
  request_header(request, "x-resolved-client-proto")
}

///|
/// Returns the trusted-proxy-resolved client host, or `None` if no
/// trusted-proxy pipeline has been applied to this request.
pub fn resolved_client_host(request : Request) -> String? {
  request_header(request, "x-resolved-client-host")
}
