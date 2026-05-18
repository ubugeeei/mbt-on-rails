///|
/// Returns the parsed entries of an `X-Forwarded-For`-style chain.
///
/// The header is split on `,`, each entry is trimmed, and empty
/// entries are discarded. The order is preserved so callers can walk
/// the chain right-to-left (most-trusted to least-trusted).
pub fn parse_forwarded_chain(header : String) -> Array[String] {
  let entries : Array[String] = []
  for part in header.split(",") {
    let cleaned = part.trim().to_owned()
    if cleaned.length() > 0 {
      entries.push(cleaned)
    }
  }
  entries
}

///|
/// Resolves the client IP from an `X-Forwarded-For` header.
///
/// The chain is walked right-to-left, skipping any hop whose value is
/// listed in `trusted_proxies`. The first non-trusted hop is returned
/// — that is the closest entry to the real client that the application
/// can vouch for. If every hop is trusted (a misconfiguration in
/// practice) the leftmost entry is returned as a best guess. An empty
/// header returns `None`.
pub fn parse_forwarded_for(
  header : String,
  trusted_proxies : Array[String],
) -> String? {
  let chain = parse_forwarded_chain(header)
  if chain.is_empty() {
    return None
  }
  let mut index = chain.length() - 1
  while index >= 0 {
    let candidate = chain[index]
    if !trusted_proxies.contains(candidate) {
      return Some(candidate)
    }
    index = index - 1
  }
  Some(chain[0])
}

///|
/// Returns the leftmost value of an `X-Forwarded-Proto` /
/// `X-Forwarded-Host` style header, trimmed and lowercased. Empty
/// headers yield `None`.
pub fn parse_forwarded_leftmost(header : String) -> String? {
  let chain = parse_forwarded_chain(header)
  if chain.is_empty() {
    None
  } else {
    Some(chain[0].to_lower())
  }
}

///|
/// Resolves the request identifier for an incoming request.
///
/// If `request` already carries the configured header, its value is
/// returned after stripping any character outside `[A-Za-z0-9_\-]`.
/// Otherwise `fallback` is returned unchanged — the caller is expected
/// to supply a fresh random identifier (UUID, base32 nonce, etc.) at
/// the boundary so that every request flowing through the framework
/// carries a stable correlation id.
pub fn resolve_request_id(
  request : Request,
  header_name : String,
  fallback : String,
) -> String {
  match request_header(request, header_name) {
    Some(existing) => sanitize_request_id(existing, fallback)
    None => fallback
  }
}

///|
fn sanitize_request_id(candidate : String, fallback : String) -> String {
  let builder = StringBuilder::new()
  for ch in candidate {
    if is_request_id_char(ch) {
      builder.write_char(ch)
    }
  }
  let rendered = builder.to_string()
  if rendered.length() == 0 {
    fallback
  } else {
    rendered
  }
}

///|
fn is_request_id_char(ch : Char) -> Bool {
  (ch >= 'A' && ch <= 'Z') ||
  (ch >= 'a' && ch <= 'z') ||
  (ch >= '0' && ch <= '9') ||
  ch == '-' ||
  ch == '_'
}
