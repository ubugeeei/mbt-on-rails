///|
/// Produces a stable demo password digest from a password and salt.
pub fn digest_password(password : String, salt : String) -> String {
  "mbor$demo$" + @support.hash_string(salt + "::" + password)
}

///|
/// Checks whether the supplied password matches a stored digest.
pub fn verify_password(
  password : String,
  salt : String,
  digest : String,
) -> Bool {
  digest_password(password, salt) == digest
}

///|
/// Issues a new session identifier and CSRF token pair.
pub fn issue_session(user_id : String, agent_hint : String) -> Session {
  let seed = user_id + "::" + agent_hint
  {
    id: "sess_" + @support.hash_string(seed),
    user_id,
    csrf_token: "csrf_" + @support.hash_string("csrf::" + seed),
    fresh: true,
  }
}

///|
/// Issues a short-lived password reset token for a user.
pub fn issue_password_reset(
  user_id : String,
  email : String,
  requested_at : String,
) -> PasswordResetToken {
  {
    token: "reset_" +
    @support.hash_string(user_id + "::" + email + "::" + requested_at),
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
) -> EmailVerificationToken {
  {
    token: "verify_" +
    @support.hash_string(user_id + "::" + email + "::" + requested_at),
    user_id,
    email,
    expires_at: requested_at + "+24h",
  }
}

///|
/// Returns whether the provided CSRF token matches the active session.
pub fn csrf_valid(session : Session?, provided : String?) -> Bool {
  match session {
    Some(current) =>
      match provided {
        Some(token) => current.csrf_token == token
        None => false
      }
    None => false
  }
}

///|
/// Builds the session cookie that should be set for a browser client.
pub fn session_cookie(
  config : AuthConfig,
  session : Session,
  remember_me : Bool,
) -> AuthCookie {
  {
    name: if remember_me {
      config.remember_cookie
    } else {
      config.session_cookie
    },
    value: session.id,
    path: "/",
    http_only: true,
    secure: true,
    same_site: "Lax",
    max_age_seconds: if remember_me {
      Some(60 * 60 * 24 * 30)
    } else {
      None
    },
  }
}

///|
/// Renders a cookie definition as a `Set-Cookie` header value.
pub fn cookie_header(cookie : AuthCookie) -> String {
  let parts : Array[String] = [
    cookie.name + "=" + cookie.value,
    "Path=" + cookie.path,
    "SameSite=" + cookie.same_site,
  ]
  if cookie.http_only {
    parts.push("HttpOnly")
  }
  if cookie.secure {
    parts.push("Secure")
  }
  match cookie.max_age_seconds {
    Some(max_age) => parts.push("Max-Age=" + max_age.to_string())
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
  config.password_reset_path
}
