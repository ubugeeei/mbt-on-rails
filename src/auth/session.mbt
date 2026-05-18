///|
/// Produces a stable demo password digest from a password and salt.
///
/// **Demo only.** This wraps a non-cryptographic hash and is here for
/// backwards compatibility with the original tutorial. Reach for
/// `digest_password_secure` / `verify_password_secure` in any code
/// that stores real user credentials.
pub fn digest_password(password : String, salt : String) -> String {
  "mbor$demo$" + @support.hash_string(salt + "::" + password)
}

///|
/// Checks whether the supplied password matches a stored digest.
///
/// Uses a constant-time comparison so an attacker cannot probe the digest
/// one byte at a time. The digest itself is still a demo construction —
/// use `verify_password_secure` against `digest_password_secure` for any
/// real credential.
pub fn verify_password(
  password : String,
  salt : String,
  digest : String,
) -> Bool {
  @support.constant_time_eq(digest_password(password, salt), digest)
}

///|
/// Builds a PBKDF2-HMAC-SHA-256 password digest in a self-describing
/// `pbkdf2$sha256$<iterations>$<salt-hex>$<hash-hex>` format.
///
/// `iterations` defaults to 600,000 — the OWASP 2025 baseline for new
/// systems. Increase it as hardware speeds up. The salt is hex-encoded
/// so any `$` characters in the caller's salt do not break parsing.
pub fn digest_password_secure(
  password : String,
  salt : String,
  iterations? : Int = 600_000,
) -> String {
  let salt_bytes = @support.utf8_bytes(salt)
  let digest_bytes = @support.pbkdf2_hmac_sha256(
    @support.utf8_bytes(password),
    salt_bytes,
    iterations,
    32,
  )
  "pbkdf2$sha256$" +
  iterations.to_string() +
  "$" +
  @support.hex_encode_bytes(salt_bytes) +
  "$" +
  @support.hex_encode_bytes(digest_bytes)
}

///|
/// Verifies a password against a digest produced by
/// `digest_password_secure`.
///
/// Parses the iteration count and salt out of the stored string, re-runs
/// PBKDF2 with the same parameters, and compares the result in constant
/// time. Returns `false` for any malformed digest rather than raising.
pub fn verify_password_secure(password : String, digest : String) -> Bool {
  match parse_pbkdf2_digest(digest) {
    Some(parsed) => {
      let candidate = @support.pbkdf2_hmac_sha256(
        @support.utf8_bytes(password),
        parsed.salt_bytes,
        parsed.iterations,
        parsed.expected_hash.length(),
      )
      let candidate_hex = @support.hex_encode_bytes(candidate)
      let expected_hex = @support.hex_encode_bytes(parsed.expected_hash)
      @support.constant_time_eq(candidate_hex, expected_hex)
    }
    None => false
  }
}

///|
struct Pbkdf2DigestParts {
  iterations : Int
  salt_bytes : Array[UInt]
  expected_hash : Array[UInt]
}

///|
fn parse_pbkdf2_digest(digest : String) -> Pbkdf2DigestParts? {
  let parts : Array[String] = []
  for chunk in digest.split("$") {
    parts.push(chunk.to_string())
  }
  if parts.length() != 5 {
    return None
  }
  if parts[0] != "pbkdf2" {
    return None
  }
  if parts[1] != "sha256" {
    return None
  }
  let iterations = match parse_positive_int(parts[2]) {
    Some(value) => value
    None => return None
  }
  let salt_bytes = match @support.hex_decode_bytes(parts[3]) {
    Some(value) => value
    None => return None
  }
  let expected_hash = match @support.hex_decode_bytes(parts[4]) {
    Some(value) => value
    None => return None
  }
  Some({ iterations, salt_bytes, expected_hash })
}

///|
fn parse_positive_int(source : String) -> Int? {
  if source.length() == 0 {
    return None
  }
  let mut result = 0
  for ch in source {
    if ch < '0' || ch > '9' {
      return None
    }
    let digit = (ch.to_uint() - '0'.to_uint()).reinterpret_as_int()
    result = result * 10 + digit
  }
  Some(result)
}

///|
/// Issues a new session identifier and CSRF token pair.
///
/// Production callers should pass per-session entropy and an application
/// secret; the fallback nonce keeps demo calls from repeating stable hints.
pub fn issue_session(
  user_id : String,
  agent_hint : String,
  entropy? : String? = None,
  secret? : String? = None,
) -> Session {
  let seed = session_seed(user_id, agent_hint, entropy, secret)
  {
    id: "sess_" + token_digest("session", seed),
    user_id,
    csrf_token: "csrf_" + token_digest("csrf", seed),
    fresh: true,
  }
}

///|
/// Rotates `current` into a brand-new session pair while preserving the
/// caller's `user_id`. Every sign-in path must call this so an attacker-
/// fixed session id does not survive the upgrade from anonymous to
/// authenticated traffic.
///
/// `entropy` and `secret` are mixed into the seed exactly as in
/// `issue_session`; the helper exists to make the rotation pattern
/// observable at the call site, not to introduce new behaviour.
pub fn rotate_session(
  current : Session,
  agent_hint : String,
  entropy? : String? = None,
  secret? : String? = None,
) -> Session {
  issue_session(current.user_id, agent_hint, entropy~, secret~)
}

///|
let session_rng : @random.Rand = @random.Rand::new()

///|
fn session_seed(
  user_id : String,
  agent_hint : String,
  entropy : String?,
  secret : String?,
) -> String {
  user_id +
  "::" +
  agent_hint +
  "::entropy=" +
  optional_seed_part(entropy) +
  "::secret=" +
  optional_seed_part(secret) +
  "::nonce=" +
  session_nonce()
}

///|
fn optional_seed_part(value : String?) -> String {
  match value {
    Some(current) => @support.hash_string(current)
    None => "none"
  }
}

///|
fn token_digest(purpose : String, seed : String) -> String {
  @support.hash_string(purpose + "::0::" + seed) +
  @support.hash_string(purpose + "::1::" + seed) +
  @support.hash_string(purpose + "::2::" + seed) +
  @support.hash_string(purpose + "::3::" + seed)
}

///|
fn session_nonce() -> String {
  session_rng.uint64().to_string() + ":" + session_rng.uint64().to_string()
}

///|
/// Issues a short-lived password reset token for a user.
pub fn issue_password_reset(
  user_id : String,
  email : String,
  requested_at : String,
  entropy? : String? = None,
  secret? : String? = None,
) -> PasswordResetToken {
  let seed = token_grant_seed(
    "password_reset", user_id, email, requested_at, entropy, secret,
  )
  {
    token: "reset_" + token_digest("password_reset", seed),
    user_id,
    email,
    expires_at: requested_at + "+15m",
  }
}

///|
/// Issues a longer-lived email verification token for a user.
pub fn issue_email_verification(
  user_id : String,
  email : String,
  requested_at : String,
  entropy? : String? = None,
  secret? : String? = None,
) -> EmailVerificationToken {
  let seed = token_grant_seed(
    "email_verification", user_id, email, requested_at, entropy, secret,
  )
  {
    token: "verify_" + token_digest("email_verification", seed),
    user_id,
    email,
    expires_at: requested_at + "+24h",
  }
}

///|
fn token_grant_seed(
  purpose : String,
  user_id : String,
  email : String,
  requested_at : String,
  entropy : String?,
  secret : String?,
) -> String {
  purpose +
  "::user=" +
  user_id +
  "::email=" +
  email +
  "::requested_at=" +
  requested_at +
  "::entropy=" +
  optional_seed_part(entropy) +
  "::secret=" +
  optional_seed_part(secret) +
  "::nonce=" +
  session_nonce()
}

///|
/// Returns whether the provided CSRF token matches the active session.
///
/// Uses a constant-time comparison so a request that only differs from
/// the expected token in the last byte does not finish faster than one
/// that diverges in the first byte.
pub fn csrf_valid(session : Session?, provided : String?) -> Bool {
  match session {
    Some(current) =>
      match provided {
        Some(token) => @support.constant_time_eq(current.csrf_token, token)
        None => false
      }
    None => false
  }
}

///|
/// Returns the lax SameSite policy.
pub fn cookie_same_site_lax() -> CookieSameSite {
  SameSiteLax
}

///|
/// Returns the strict SameSite policy.
pub fn cookie_same_site_strict() -> CookieSameSite {
  SameSiteStrict
}

///|
/// Returns the `None` SameSite policy.
pub fn cookie_same_site_none() -> CookieSameSite {
  SameSiteNone
}

///|
/// Builds a signed cookie-store session backend.
#label_migration(key, allow_positional=true)
pub fn cookie_session_store(
  key~ : String,
  expire_after_seconds? : Int? = None,
  secure? : Bool = true,
  http_only? : Bool = true,
  same_site? : CookieSameSite = SameSiteLax,
  signed? : Bool = true,
  path? : String = "/",
  domain? : String? = None,
  renew? : Bool = false,
  signing_secret? : String? = None,
) -> SessionStore {
  let secure = secure || same_site == SameSiteNone
  {
    kind: CookieStore,
    key,
    expire_after_seconds,
    secure,
    http_only,
    same_site,
    signed,
    path,
    domain,
    renew,
    signing_secret,
  }
}

///|
/// Builds a cache-backed session backend.
#label_migration(key, allow_positional=true)
pub fn cache_session_store(
  key~ : String,
  expire_after_seconds? : Int? = None,
  secure? : Bool = true,
  http_only? : Bool = true,
  same_site? : CookieSameSite = SameSiteLax,
  path? : String = "/",
  domain? : String? = None,
  renew? : Bool = false,
) -> SessionStore {
  let secure = secure || same_site == SameSiteNone
  {
    kind: CacheStore,
    key,
    expire_after_seconds,
    secure,
    http_only,
    same_site,
    signed: false,
    path,
    domain,
    renew,
    signing_secret: None,
  }
}

///|
/// Builds a redis-backed session backend.
#label_migration(key, allow_positional=true)
pub fn redis_session_store(
  key~ : String,
  expire_after_seconds? : Int? = None,
  secure? : Bool = true,
  http_only? : Bool = true,
  same_site? : CookieSameSite = SameSiteLax,
  path? : String = "/",
  domain? : String? = None,
  renew? : Bool = false,
) -> SessionStore {
  let secure = secure || same_site == SameSiteNone
  {
    kind: RedisStore,
    key,
    expire_after_seconds,
    secure,
    http_only,
    same_site,
    signed: false,
    path,
    domain,
    renew,
    signing_secret: None,
  }
}

///|
/// Builds a disabled session backend for APIs that opt out entirely.
pub fn disabled_session_store() -> SessionStore {
  {
    kind: DisabledStore,
    key: "",
    expire_after_seconds: None,
    secure: true,
    http_only: true,
    same_site: SameSiteLax,
    signed: false,
    path: "/",
    domain: None,
    renew: false,
    signing_secret: None,
  }
}

///|
/// Returns the default cookie-backed store implied by the auth config.
#label_migration(config, allow_positional=true)
#label_migration(remember_me, allow_positional=true)
pub fn session_store_for_config(
  config~ : AuthConfig,
  remember_me~ : Bool,
) -> SessionStore {
  cookie_session_store(
    key=if remember_me { config.remember_cookie } else { config.session_cookie },
    expire_after_seconds=if remember_me {
      Some(60 * 60 * 24 * 30)
    } else {
      None
    },
    secure=true,
    http_only=true,
    same_site=SameSiteLax,
    signing_secret=Some(config.secret_key_base),
  )
}

///|
/// Signs one cookie value using the supplied secret.
///
/// The signature is `HMAC-SHA-256(secret, name || "::" || value)` rendered as
/// a lowercase hex string. The resulting cookie is encoded as
/// `value--<hex-tag>` so verifiers can locate the delimiter even when the
/// value itself contains literal `--` sequences (only the final `--`
/// counts).
pub fn sign_cookie_value(
  name : String,
  value : String,
  secret : String,
) -> String {
  value + "--" + @support.hmac_sha256_hex(secret, name + "::" + value)
}

///|
/// Verifies and unwraps one signed cookie value.
pub fn verify_signed_cookie_value(
  name : String,
  signed_value : String,
  secret : String,
) -> String? {
  match find_final_signature_delimiter(signed_value) {
    Some(index) => {
      let value = String::unsafe_substring(signed_value, start=0, end=index)
      let digest = String::unsafe_substring(
        signed_value,
        start=index + 2,
        end=signed_value.length(),
      )
      let expected = @support.hmac_sha256_hex(secret, name + "::" + value)
      if @support.constant_time_eq(digest, expected) {
        Some(value)
      } else {
        None
      }
    }
    None => None
  }
}

///|
fn find_final_signature_delimiter(source : String) -> Int? {
  let mut delimiter : Int? = None
  let mut index = 0
  while index + 2 <= source.length() {
    if String::unsafe_substring(source, start=index, end=index + 2) == "--" {
      delimiter = Some(index)
    }
    index += 1
  }
  delimiter
}

///|
/// Builds one explicitly signed cookie.
#label_migration(name, allow_positional=true)
#label_migration(value, allow_positional=true)
#label_migration(secret, allow_positional=true)
pub fn signed_cookie(
  name~ : String,
  value~ : String,
  secret~ : String,
  path? : String = "/",
  domain? : String? = None,
  http_only? : Bool = true,
  secure? : Bool = true,
  same_site? : CookieSameSite = SameSiteLax,
  max_age_seconds? : Int? = None,
  expires_at? : String? = None,
) -> AuthCookie {
  let secure = secure || same_site == SameSiteNone
  {
    name,
    value: sign_cookie_value(name, value, secret),
    path,
    domain,
    http_only,
    secure,
    same_site,
    signed: true,
    max_age_seconds,
    expires_at,
  }
}

///|
/// Parses one raw `Cookie` header into flat key/value pairs.
pub fn parse_cookie_header(header : String) -> Array[(String, String)] {
  let entries : Array[(String, String)] = []
  for part in header.split(";") {
    let current = part.trim().to_owned()
    if current.length() == 0 {
      continue
    }
    match current.find("=") {
      Some(index) => {
        let key = String::unsafe_substring(current, start=0, end=index)
          .trim()
          .to_owned()
        let value = String::unsafe_substring(
            current,
            start=index + 1,
            end=current.length(),
          )
          .trim()
          .to_owned()
        entries.push((key, value))
      }
      None => ()
    }
  }
  entries
}

///|
/// Finds one cookie value in a parsed cookie list.
pub fn find_cookie(cookies : Array[(String, String)], name : String) -> String? {
  @support.find_entry(cookies, name)
}

///|
/// Returns the exception-based forgery strategy.
pub fn request_forgery_exception() -> RequestForgeryStrategy {
  ExceptionStrategy
}

///|
/// Returns the null-session forgery strategy.
pub fn request_forgery_null_session() -> RequestForgeryStrategy {
  NullSessionStrategy
}

///|
/// Returns the reset-session forgery strategy.
pub fn request_forgery_reset_session() -> RequestForgeryStrategy {
  ResetSessionStrategy
}

///|
/// Applies the selected request forgery strategy to a CSRF check.
pub fn protect_from_forgery(
  session : Session?,
  provided : String?,
  strategy : RequestForgeryStrategy,
) -> RequestForgeryOutcome {
  if csrf_valid(session, provided) {
    return Verified(session)
  }
  match strategy {
    ExceptionStrategy => Rejected("invalid_csrf_token")
    NullSessionStrategy => NullSession
    ResetSessionStrategy => ResetSession
  }
}

///|
/// Summarizes one request forgery strategy for diagnostics.
pub fn forgery_strategy_summary(strategy : RequestForgeryStrategy) -> String {
  match strategy {
    ExceptionStrategy => "exception"
    NullSessionStrategy => "null_session"
    ResetSessionStrategy => "reset_session"
  }
}

///|
/// Summarizes one session store for diagnostics and docs.
pub fn session_store_summary(store : SessionStore) -> String {
  "store=" +
  render_session_store_kind(store.kind) +
  " key=" +
  store.key +
  " signed=" +
  store.signed.to_string() +
  " same_site=" +
  render_cookie_same_site(store.same_site)
}

///|
/// Builds the session cookie that should be set for a browser client.
#label_migration(config, allow_positional=true)
#label_migration(session, allow_positional=true)
#label_migration(remember_me, allow_positional=true)
pub fn session_cookie(
  config~ : AuthConfig,
  session~ : Session,
  remember_me~ : Bool,
) -> AuthCookie {
  session_cookie_with_store(
    store=session_store_for_config(config~, remember_me~),
    session~,
  )
}

///|
/// Builds the session cookie for one explicit session store.
#label_migration(store, allow_positional=true)
#label_migration(session, allow_positional=true)
pub fn session_cookie_with_store(
  store~ : SessionStore,
  session~ : Session,
) -> AuthCookie {
  let secure = store.secure || store.same_site == SameSiteNone
  let value = if store.signed {
    match store.signing_secret {
      Some(secret) => sign_cookie_value(store.key, session.id, secret)
      None => ""
    }
  } else {
    session.id
  }
  {
    name: store.key,
    value,
    path: store.path,
    domain: store.domain,
    http_only: store.http_only,
    secure,
    same_site: store.same_site,
    signed: store.signed,
    max_age_seconds: store.expire_after_seconds,
    expires_at: None,
  }
}

///|
/// Renders a cookie definition as a `Set-Cookie` header value.
pub fn cookie_header(cookie : AuthCookie) -> String {
  let name = cookie_header_token(cookie.name)
  let value = cookie_header_value(cookie.value)
  let path = cookie_header_value(cookie.path)
  let parts : Array[String] = [
    name + "=" + value,
    "Path=" + path,
    "SameSite=" + render_cookie_same_site(cookie.same_site),
  ]
  match cookie.domain {
    Some(domain) => parts.push("Domain=" + cookie_header_value(domain))
    None => ()
  }
  if cookie.http_only {
    parts.push("HttpOnly")
  }
  if cookie.secure || cookie.same_site == SameSiteNone {
    parts.push("Secure")
  }
  match cookie.max_age_seconds {
    Some(max_age) => parts.push("Max-Age=" + max_age.to_string())
    None => ()
  }
  match cookie.expires_at {
    Some(expires_at) => parts.push("Expires=" + cookie_header_value(expires_at))
    None => ()
  }
  parts.join("; ")
}

///|
/// Summarizes the authentication setup for CLI output and docs.
pub fn auth_summary(config : AuthConfig) -> String {
  "auth user=" +
  config.user_model +
  " session=" +
  config.session_model +
  " sign_in=" +
  config.sign_in_path +
  " sign_out=" +
  config.sign_out_path +
  " reset=" +
  config.password_reset_path +
  " session_store=" +
  config.session_cookie
}

///|
fn render_cookie_same_site(policy : CookieSameSite) -> String {
  match policy {
    SameSiteStrict => "Strict"
    SameSiteLax => "Lax"
    SameSiteNone => "None"
  }
}

///|
fn render_session_store_kind(kind : SessionStoreKind) -> String {
  match kind {
    CookieStore => "cookie"
    CacheStore => "cache"
    RedisStore => "redis"
    DisabledStore => "disabled"
  }
}

///|
fn cookie_header_token(source : String) -> String {
  let builder = StringBuilder::new()
  for ch in source {
    if is_cookie_token_char(ch) {
      builder.write_char(ch)
    } else {
      builder.write_char('_')
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
fn cookie_header_value(source : String) -> String {
  let builder = StringBuilder::new()
  for ch in source {
    match ch {
      '\n' | '\r' => break
      ';' => builder.write_char(' ')
      _ => builder.write_char(ch)
    }
  }
  builder.to_string().trim().to_owned()
}

///|
fn is_cookie_token_char(ch : Char) -> Bool {
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
