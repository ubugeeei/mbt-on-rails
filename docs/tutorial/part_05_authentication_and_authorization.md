# Part 5: Authentication and Authorization

## Goal

Learn how sign-in state, CSRF, and policy checks work.

## Key Files

- [`../../src/auth/types.mbt`](../../src/auth/types.mbt)
- [`../../src/auth/session.mbt`](../../src/auth/session.mbt)
- [`../../src/auth/policy.mbt`](../../src/auth/policy.mbt)
- [`../../examples/auth_policy/main.mbt`](../../examples/auth_policy/main.mbt)

## Identity And Requirements

Auth is modeled through explicit values:

- `identity(...)`
- `auth_public()`
- `auth_guest_only()`
- `auth_required()`
- `role_access(...)`
- `permission_access(...)`

This makes requirements inspectable and easy to feed into controller plans.

## Sessions And CSRF

Session helpers include:

- `issue_session(...)`
- `session_store_for_config(...)`
- `session_cookie(...)`
- `session_cookie_with_store(...)`
- `request_header(...)`
- `request_cookie(...)`
- `request_session_id(...)`
- `with_request_session(...)`
- `request_csrf_token(...)`
- `csrf_valid(...)`
- `protect_from_forgery(...)`
- `signed_cookie(...)`
- `parse_cookie_header(...)`
- `issue_password_reset(...)`
- `issue_email_verification(...)`

The current implementation is still lightweight, but it now models:

- typed cookie SameSite policies
- explicit cookie / cache / redis session stores
- signed cookie values
- request-side cookie and session resolution helpers
- explicit forgery strategies such as exception, null-session, and reset-session
- Action Pack-style response helpers such as `append_set_cookie(...)`, `see_other_response(...)`, and `unprocessable_entity_response(...)`

Example:

```moonbit
let store = session_store_for_config(
  config=config,
  remember_me=true,
)
let cookie = session_cookie(
  config=config,
  session=session,
  remember_me=true,
)
let checked = protect_from_forgery(
  Some(session),
  request_csrf_token(
    with_request_session(
      append_request_header(
        request(
          verb=http_post(),
          path="/posts",
          query=[],
          form=[],
          session_id=None,
          body="",
        ),
        "X-CSRF-Token",
        session.csrf_token,
      ),
      store~,
    ),
    config,
  ),
  request_forgery_exception(),
)
```

## Policy Rules

Use `policy_rule(...)` and `authorize(...)` to model access checks.

```moonbit
let owner_rule = policy_rule(
  resource="posts",
  action="update",
  roles=[],
  permissions=[],
  allow_owner=true,
)
```

In this repository, the important design choice is:

- auth state is explicit
- policy state is explicit
- controller requirements stay declarative

## Demo To Read

- [`../../examples/auth_policy/main.mbt`](../../examples/auth_policy/main.mbt)
- [`../../tests/public/auth_api_wbtest.mbt`](../../tests/public/auth_api_wbtest.mbt)

## Exercise

- Build an `editor` identity
- Check `authorize(Some(editor), permission_access("posts.publish"))`
- Check `authorize(Some(editor), role_access("admin"))`

## Next

Continue to [Part 6: Views, Layouts, and Templates](part_06_views_layouts_and_templates.md).
