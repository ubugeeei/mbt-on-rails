///|
test "rotate_session preserves user id while minting a new id and csrf token" {
  let initial = issue_session(
    "user-42",
    "browser",
    entropy=Some("entropy-a"),
    secret=Some("secret-key-base"),
  )
  let rotated = rotate_session(
    initial,
    "browser",
    entropy=Some("entropy-b"),
    secret=Some("secret-key-base"),
  )
  assert_eq(rotated.user_id, "user-42")
  assert_true(rotated.id.has_prefix("sess_"))
  assert_true(rotated.csrf_token.has_prefix("csrf_"))
  assert_false(rotated.id == initial.id)
  assert_false(rotated.csrf_token == initial.csrf_token)
  assert_true(rotated.fresh)
}

///|
test "rotate_session returns a fresh pair on every call even without entropy" {
  let initial = issue_session("user-1", "browser")
  let once = rotate_session(initial, "browser")
  let twice = rotate_session(once, "browser")
  assert_false(once.id == initial.id)
  assert_false(twice.id == once.id)
  assert_false(once.csrf_token == initial.csrf_token)
  assert_false(twice.csrf_token == once.csrf_token)
  assert_eq(once.user_id, "user-1")
  assert_eq(twice.user_id, "user-1")
}

///|
test "rotate_session csrf_valid still matches the new token after rotation" {
  let initial = issue_session("user-1", "browser")
  let rotated = rotate_session(initial, "browser")
  assert_true(csrf_valid(Some(rotated), Some(rotated.csrf_token)))
  assert_false(csrf_valid(Some(rotated), Some(initial.csrf_token)))
}
