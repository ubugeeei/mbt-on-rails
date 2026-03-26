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
- `session_cookie(...)`
- `csrf_valid(...)`
- `issue_password_reset(...)`
- `issue_email_verification(...)`

The current implementation is intentionally lightweight but typed.

## Policy Rules

Use `policy_rule(...)` and `authorize(...)` to model access checks.

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
