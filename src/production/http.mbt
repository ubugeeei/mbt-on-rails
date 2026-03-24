///|
/// Builds a health endpoint response from probe results.
pub fn health_response(checks : Array[HealthCheck]) -> @http.Response {
  build_probe_response(checks)
}

///|
/// Builds a readiness endpoint response from probe results.
pub fn readiness_response(checks : Array[HealthCheck]) -> @http.Response {
  build_probe_response(checks)
}

///|
/// Builds a metrics endpoint response from a Prometheus registry body.
pub fn metrics_response(body : String) -> @http.Response {
  @http.typed_text_response(
    200, "text/plain; version=0.0.4; charset=utf-8", body,
  )
}

///|
/// Builds one JSON API success response.
pub fn json_api_ok(
  resource_type : String,
  id : String,
  attributes : Array[(String, String)],
) -> @http.Response {
  @http.ok_json(json_api_document(resource_type, id, attributes, []))
}

///|
/// Builds one JSON API error response.
pub fn json_api_error(
  status : Int,
  code : String,
  detail : String,
) -> @http.Response {
  @http.json_response(
    status,
    "{" +
    "\"errors\": [{" +
    "\"status\": " +
    @support.json_string(status.to_string()) +
    ", \"code\": " +
    @support.json_string(code) +
    ", \"detail\": " +
    @support.json_string(detail) +
    "}]" +
    "}",
  )
}

///|
/// Renders a compact JSON API document body.
pub fn json_api_document(
  resource_type : String,
  id : String,
  attributes : Array[(String, String)],
  meta : Array[(String, String)],
) -> String {
  "{" +
  "\"data\": {" +
  "\"type\": " +
  @support.json_string(resource_type) +
  ", \"id\": " +
  @support.json_string(id) +
  ", \"attributes\": " +
  @support.entries_to_json(attributes) +
  "}" +
  (if meta.is_empty() {
    ""
  } else {
    ", \"meta\": " + @support.entries_to_json(meta)
  }) +
  "}"
}

///|
/// Builds a shared probe response with `200` or `503`.
fn build_probe_response(checks : Array[HealthCheck]) -> @http.Response {
  let status = if all_checks_ok(checks) { 200 } else { 503 }
  @http.typed_text_response(
    status,
    "application/json; charset=utf-8",
    render_health_json(checks),
  )
}

///|
/// Returns whether every probe is currently healthy.
fn all_checks_ok(checks : Array[HealthCheck]) -> Bool {
  for check in checks {
    if not(check.ok) {
      return false
    }
  }
  true
}
