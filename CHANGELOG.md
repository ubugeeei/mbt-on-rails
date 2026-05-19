# Changelog

All notable changes to `mbt_on_rails` are tracked here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
intends to follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
once it stabilises. Pre-1.0, expect that minor bumps may include breaking
changes; breaking changes are always called out under `### Changed` or
`### Removed`.

## [Unreleased]

### Added — observability

- `@production.LogSink` contract with `log_sink`, `null_log_sink`,
  `captured_log_sink`, and `json_lines_log_sink` drivers, plus
  `log_sink_emit` / `log_sink_close` / `log_sink_summary` /
  `log_sink_error_message` helpers. Mirrors the shape of `SmtpAdapter`
  and `CacheAdapter` so concrete sinks (stdout, file, network shipper)
  can plug in uniformly. Refs #117.

## [0.2.0] — 2026-05-19

Production-readiness bundle landed on top of the 0.1.0 baseline. This is
still pre-1.0 — the surface listed in `pkg.generated.mbti` is the
contract, breaking changes are called out below, and `unsafe_*`-prefixed
APIs are intentionally allowed for one minor release before they get
their soft-deprecation warnings.

### Added — security

- `@support.constant_time_eq(left, right)`: length-aware accumulator-based
  string compare. Used by `verify_password`, `csrf_valid`, and
  `verify_signed_cookie_value` so a request that only differs at the last
  byte does not finish faster than one that diverges at the first byte.
- `@support.sha256_bytes` / `sha256_hex` (FIPS 180-4) and
  `@support.hmac_sha256_bytes` / `hmac_sha256_hex` (RFC 2104) implemented
  self-contained, with RFC 4231 KAT vectors as public tests.
- `@support.utf8_bytes` and `@support.hex_encode_bytes` round-trip helpers
  for the cryptographic primitives above.
- `sign_cookie_value` and `verify_signed_cookie_value` now produce and
  verify HMAC-SHA-256 tags instead of the DJB2 hash they used in 0.1.0.
- `is_safe_internal_redirect(path)` and `redirect_response_to_external(url)`
  alongside a strict internal-only contract for `redirect_response` and
  `see_other_response`. External or unsafe redirect targets now produce a
  `400 Bad Request` rather than a `Location` header.
- `escape_html_text` / `escape_html_attribute` / `escape_js_string` /
  `escape_url_component` / `escape_css_value` context-aware escape
  helpers in `@support`.
- `rotate_session(session, entropy~, secret~)` for explicit session-ID
  rotation on sign-in.
- `nosniff_middleware`, `frame_options_middleware`,
  `referrer_policy_middleware`, `hsts_middleware`,
  `content_security_policy_middleware`, `cors_middleware`,
  `default_security_headers_bundle` plus the configuration types
  (`ContentSecurityPolicy`, `CorsConfig`, `FrameOptionsMode`).

### Added — Active Record

- `RelationBind` enum plus `where_with_binds`, `having_with_binds`,
  `render_relation_bind`, `substitute_relation_binds` for parameterised
  predicate construction. `unsafe_where_raw` / `unsafe_having_raw` /
  `unsafe_join_relation` aliases flag the existing raw builders as
  trust-the-caller.
- `CallbackOutcome` plus `run_record_callbacks`,
  `save_record_with_callbacks`, `destroy_record_with_callbacks` to make
  the previously dead Callback metadata actually runnable.
- `DatabaseAdapter` contract (Stage 1) with `AdapterError`,
  `QueryOutcome`, `QueryResult`, `TxHandle`,
  `TransactionBeginOutcome`, `TransactionCloseOutcome`,
  `adapter_execute` / `adapter_begin` / `adapter_commit` /
  `adapter_rollback` / `adapter_close` call helpers, plus
  `null_database_adapter()` placeholder. Concrete drivers follow in
  separate releases.

### Added — HTTP

- `parse_forwarded_chain`, `parse_forwarded_for(header, trusted_proxies)`,
  `parse_forwarded_leftmost` helpers for `X-Forwarded-*` parsing against
  a trusted-proxy allowlist.
- `resolve_request_id(request, header_name, fallback)` plus the
  injection-safe sanitiser behind it.

### Added — governance

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
- `sign_cookie_value` / `verify_signed_cookie_value` switched from the
  DJB2 hash to HMAC-SHA-256. Cookies signed under 0.1.0 will no longer
  verify under 0.2.0 — they were forgeable by design, so this is the
  intended migration. Re-issue affected sessions / CSRF / password-reset
  tokens.

### Security

- Equality checks on signed cookie digests, CSRF tokens, and password
  digests are now constant-time (resolves the timing-side-channel class).
- `where_raw`, `having_raw`, and `join_relation` keep their existing
  behaviour but gain documentation warning about SQL injection risk and
  `unsafe_*` aliases so future call sites can be audited mechanically.
- `redirect_response` / `see_other_response` close the open-redirect
  class by refusing external targets unless the caller explicitly opts
  in through `redirect_response_to_external`.

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

[Unreleased]: https://github.com/ubugeeei/mbt-on-rails/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/ubugeeei/mbt-on-rails/releases/tag/v0.2.0
[0.1.0]: https://github.com/ubugeeei/mbt-on-rails/releases/tag/v0.1.0
