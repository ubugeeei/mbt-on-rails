///|
test "auth policy example helpers keep identities and requirements stable" {
  let current = editor()
  assert_eq(current.user_id, "7")
  assert_eq(current.role, "editor")
  assert_true(@mbor.authorize(Some(current), @mbor.auth_required()))
  assert_true(
    @mbor.authorize(Some(current), @mbor.permission_access("posts.publish")),
  )
  assert_false(@mbor.authorize(Some(current), @mbor.role_access("admin")))

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
  assert_true(@mbor.allowed(Some(current), publish_rule, None))
  assert_true(@mbor.allowed(Some(current), owner_rule, Some("7")))
  assert_false(@mbor.allowed(Some(current), owner_rule, Some("9")))
}

///|
test "auth policy example prints and main smoke stay runnable" {
  let current = editor()
  print_requirement_checks(current)
  print_policy_checks(current)
  print_session_checks(current)
  run_example()
  assert_true(true)
}
