///|
/// Describes the level of authentication required for a route or action.
pub enum AuthRequirement {
  Public
  GuestOnly
  Authenticated
  Role(String)
  Permission(String)
} derive(Eq, Show)

///|
/// Represents the authenticated user attached to a request.
pub struct Identity {
  user_id : String
  email : String
  role : String
  permissions : Array[String]
  tenant_id : String?
}

///|
/// Stores the session identifier and CSRF token issued to a client.
pub struct Session {
  id : String
  user_id : String
  csrf_token : String
  fresh : Bool
} derive(Eq, Show)

///|
/// Lists the cookie SameSite policies supported by the auth helpers.
pub enum CookieSameSite {
  SameSiteStrict
  SameSiteLax
  SameSiteNone
} derive(Eq, Show)

///|
/// Lists the session backends modeled by the auth layer.
pub enum SessionStoreKind {
  CookieStore
  CacheStore
  RedisStore
  DisabledStore
} derive(Eq, Show)

///|
/// Lists the request forgery strategies supported by the auth helpers.
pub enum RequestForgeryStrategy {
  ExceptionStrategy
  NullSessionStrategy
  ResetSessionStrategy
} derive(Eq, Show)

///|
/// Represents the result of a request forgery check.
pub enum RequestForgeryOutcome {
  Verified(Session?)
  NullSession
  ResetSession
  Rejected(String)
} derive(Eq, Show)

///|
/// Declares policy checks for resource-oriented authorization.
pub struct PolicyRule {
  resource : String
  action : String
  roles : Array[String]
  permissions : Array[String]
  allow_owner : Bool
}

///|
/// Represents a time-limited password reset grant.
pub struct PasswordResetToken {
  token : String
  user_id : String
  email : String
  expires_at : String
}

///|
/// Represents a time-limited email verification grant.
pub struct EmailVerificationToken {
  token : String
  user_id : String
  email : String
  expires_at : String
}

///|
/// Describes the cookie that should be written by the response layer.
pub struct AuthCookie {
  name : String
  value : String
  path : String
  domain : String?
  http_only : Bool
  secure : Bool
  same_site : CookieSameSite
  signed : Bool
  max_age_seconds : Int?
  expires_at : String?
}

///|
/// Describes how sessions are persisted between requests.
pub struct SessionStore {
  kind : SessionStoreKind
  key : String
  expire_after_seconds : Int?
  secure : Bool
  http_only : Bool
  same_site : CookieSameSite
  signed : Bool
  path : String
  domain : String?
  renew : Bool
  signing_secret : String?
}

///|
/// Collects framework-level authentication configuration.
pub struct AuthConfig {
  user_model : String
  session_model : String
  session_cookie : String
  csrf_header : String
  sign_in_path : String
  sign_out_path : String
  password_reset_path : String
  verify_email_path : String
  remember_cookie : String
  secret_key_base : String
}

///|
/// Returns the default authentication wiring used by the demo app.
pub fn default_auth_config() -> AuthConfig {
  {
    user_model: "User",
    session_model: "Session",
    session_cookie: "_mbt_on_rails_session",
    csrf_header: "x-csrf-token",
    sign_in_path: "/sign-in",
    sign_out_path: "/sign-out",
    password_reset_path: "/password/reset",
    verify_email_path: "/verify-email",
    remember_cookie: "_mbt_on_rails_remember",
    secret_key_base: "mbt_on_rails_dev_secret_key_base",
  }
}

///|
/// Builds an `Identity` record for authorization checks.
pub fn identity(
  user_id : String,
  email : String,
  role : String,
  permissions : Array[String],
  tenant_id : String?,
) -> Identity {
  { user_id, email, role, permissions, tenant_id }
}

///|
/// Builds a policy rule for resource/action authorization.
#label_migration(resource, allow_positional=true)
#label_migration(action, allow_positional=true)
#label_migration(roles, allow_positional=true)
#label_migration(permissions, allow_positional=true)
#label_migration(allow_owner, allow_positional=true)
pub fn policy_rule(
  resource~ : String,
  action~ : String,
  roles~ : Array[String],
  permissions~ : Array[String],
  allow_owner~ : Bool,
) -> PolicyRule {
  { resource, action, roles, permissions, allow_owner }
}

///|
/// Returns a requirement that allows both guests and signed-in users.
pub fn auth_public() -> AuthRequirement {
  Public
}

///|
/// Returns a requirement that only guests satisfy.
pub fn auth_guest_only() -> AuthRequirement {
  GuestOnly
}

///|
/// Returns a requirement that only signed-in users satisfy.
pub fn auth_required() -> AuthRequirement {
  Authenticated
}

///|
/// Returns a requirement scoped to a specific role.
pub fn role_access(role : String) -> AuthRequirement {
  Role(role)
}

///|
/// Returns a requirement scoped to a specific permission.
pub fn permission_access(permission : String) -> AuthRequirement {
  Permission(permission)
}

///|
/// Renders a requirement in the compact strings used by summaries.
pub fn render_auth_requirement(requirement : AuthRequirement) -> String {
  match requirement {
    Public => "public"
    GuestOnly => "guest"
    Authenticated => "authenticated"
    Role(role) => "role:" + role
    Permission(permission) => "permission:" + permission
  }
}
