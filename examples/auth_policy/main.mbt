///|
/// Builds an editor identity used by the example checks.
fn editor() -> @mbor.Identity {
  @mbor.identity(
    "7",
    "editor@example.com",
    "editor",
    ["posts.publish", "posts.edit"],
    Some("tenant_1"),
  )
}

///|
/// Prints direct auth requirement checks.
fn print_requirement_checks(identity : @mbor.Identity) -> Unit {
  println("Requirement Checks")
  println(
    "authenticated = " +
    @mbor.authorize(Some(identity), @mbor.auth_required()).to_string(),
  )
  println(
    "role:admin = " +
    @mbor.authorize(Some(identity), @mbor.role_access("admin")).to_string(),
  )
  println(
    "permission:posts.publish = " +
    @mbor.authorize(Some(identity), @mbor.permission_access("posts.publish")).to_string(),
  )
  println(
    "guest only = " + @mbor.authorize(None, @mbor.auth_guest_only()).to_string(),
  )
}

///|
/// Prints policy-rule checks, including owner access.
fn print_policy_checks(identity : @mbor.Identity) -> Unit {
  let publish_rule = @mbor.policy_rule(
    resource="posts",
    action="publish",
    roles=["editor"],
    permissions=["posts.publish"],
    allow_owner=false,
  )
  let owner_rule = @mbor.policy_rule(
    resource="posts",
    action="update",
    roles=[],
    permissions=[],
    allow_owner=true,
  )

  println("Policy Checks")
  println(
    "publish rule = " +
    @mbor.allowed(Some(identity), publish_rule, None).to_string(),
  )
  println(
    "owner rule (owner) = " +
    @mbor.allowed(Some(identity), owner_rule, Some("7")).to_string(),
  )
  println(
    "owner rule (other) = " +
    @mbor.allowed(Some(identity), owner_rule, Some("9")).to_string(),
  )
}

///|
/// Prints session, cookie, and CSRF behavior.
fn print_session_checks(identity : @mbor.Identity) -> Unit {
  let config = @mbor.default_auth_config()
  let session = @mbor.issue_session(identity.user_id, "examples/auth_policy")
  let cookie = @mbor.session_cookie(config~, session~, remember_me=true)

  println("Session + Cookie")
  println("session id = " + session.id)
  println(
    "csrf valid = " +
    @mbor.csrf_valid(Some(session), Some(session.csrf_token)).to_string(),
  )
  println("cookie = " + @mbor.cookie_header(cookie))
}

///|
/// Runs the auth and policy example output.
fn run_example() -> Unit {
  let identity = editor()
  println("Auth + Policy Example")
  println("=====================")
  println("")
  print_requirement_checks(identity)
  println("")
  print_policy_checks(identity)
  println("")
  print_session_checks(identity)
}

///|
fn main {
  run_example()
}
