# Changelog

All notable changes to `mbt_on_rails` are tracked here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
intends to follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
once it stabilises. Pre-1.0, expect that minor bumps may include breaking
changes; breaking changes are always called out under `### Changed` or
`### Removed`.

## [Unreleased]

### Added

- `@support.constant_time_eq(left, right)`: length-aware accumulator-based
  string compare. Used by `verify_password`, `csrf_valid`, and
  `verify_signed_cookie_value` so a request that only differs at the last
  byte does not finish faster than one that diverges at the first byte.
- `is_safe_internal_redirect(path)` and `redirect_response_to_external(url)`
  alongside a strict internal-only contract for `redirect_response` and
  `see_other_response`. External or unsafe redirect targets now produce a
  `400 Bad Request` rather than a `Location` header.
- `RelationBind` enum plus `where_with_binds`, `having_with_binds`,
  `render_relation_bind`, `substitute_relation_binds` for parameterised
  predicate construction. `unsafe_where_raw` / `unsafe_having_raw` /
  `unsafe_join_relation` aliases flag the existing raw builders as
  trust-the-caller.
- `CONTRIBUTING.md`, GitHub issue and pull request templates, and an
  issue-template config that points security disclosure at the private
  advisory form.
- This `CHANGELOG.md`.

### Changed

- `redirect_response` and `see_other_response` now reject external schemes,
  protocol-relative URLs, paths starting with `\\`, and any input containing
  ASCII control characters. Callers that genuinely need to redirect off-site
  must use the new `redirect_response_to_external`.
- `@support.hash_string` is now documented as **non-cryptographic**. Do not
  use it as a MAC, signature, or password digest.

### Security

- Equality checks on signed cookie digests, CSRF tokens, and password
  digests are now constant-time (resolves the timing-side-channel class).
- `where_raw`, `having_raw`, and `join_relation` keep their existing
  behaviour but gain documentation warning about SQL injection risk and
  `unsafe_*` aliases so future call sites can be audited mechanically.

## [0.1.0] — 2026-05-18

Initial public surface. Coverage of the major Rails-shaped surfaces:

- Routing with `resources`, `scope`, `namespace`.
- Declarative controllers, before/after/around callback metadata, action
  plans.
- Active Record-style schema, scopes, relations, in-memory relation
  execution, typed attribute casting/serialisation, reusable validators,
  update-aware/default-aware persistence, dirty tracking, in-memory
  transactions, and migration plans with phased column/constraint safety
  analysis.
- Auth, signed cookies, request/session helpers, session-store builders,
  policies, and CSRF helpers.
- `.mbtv` pages, layouts, partials, Action View-style HTML helpers,
  server components, client islands, and suspense-like boundaries.
- Server actions, form bindings, typed form builders, generated typed
  route/action helpers.
- Vapor Moon-compatible scope ids, client module paths, template refs,
  prop/emit/slot metadata.
- Jobs, adapter contracts, serialised job envelopes, mailers, cache,
  cable, turbo stream, production helpers.
- Rails-style runtime notifications for controller, view, cache, job,
  and mailer flows.

Before `v0.1.0` the project shipped a long sequence of "harden" PRs
(#47–#85) that closed concrete defects in the auth, ORM, view, HTTP,
middleware, params, and CI surfaces; see `git log` for the full list.

[Unreleased]: https://github.com/ubugeeei/mbt-on-rails/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/ubugeeei/mbt-on-rails/releases/tag/v0.1.0
