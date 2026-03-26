# Rails Alignment

This repository is still intentionally much smaller than Rails, so "implement everything" has to happen in slices instead of one giant jump.

The source audit in this batch was anchored to the official Rails repository at:

- `activesupport/lib/active_support`
- `activemodel/lib/active_model`
- `activerecord/lib/active_record`
- `actionpack/lib/action_controller`
- `actionview/lib/action_view`
- `activejob/lib/active_job`
- `actioncable/lib/action_cable`
- `railties/lib/rails`

## First batch added here

- Rails-style notification capture modeled after `ActiveSupport::Notifications`
- `start_processing.action_controller`
- `process_action.action_controller`
- `render_template.action_view`
- `render_layout.action_view`
- `cache_read.active_support`
- `cache_generate.active_support`
- `cache_write.active_support`
- `cache_delete.active_support`
- `cache_delete_matched.active_support`
- `enqueue.active_job`
- `enqueue_at.active_job`
- `enqueue_retry.active_job`
- `retry_stopped.active_job`
- `perform_start.active_job`
- `process.action_mailer`

## Second batch added here

- `ActiveModel::Errors`-like typed validation results via `ValidationError`, `ValidationErrors`, and `validate_record_errors`
- A valibot-like validation layer in `src/validation` with composable `object_schema` / `string_field` / `FieldRule`
- `ActiveRecord` validation wrappers can now bridge to generic rules through `validates(field=..., rule=...)`
- Validation constructors and association constructors now support labelled arguments for a more declarative API

## Third batch added here

- `ActiveJob`-style `retry_on` / `discard_on` failure policies with typed `RetryWait` and `JobFailurePolicy`
- Failure handling now returns `JobFailureOutcome` and can reschedule jobs using fixed or polynomial backoff
- Active Job notifications now include `discard.active_job` in addition to retry-related events

## Fourth batch added here

- Resource-aware scaffolds now infer `belongs_to` associations, presence/slug validations, strong params, CRUD pages, forms, and a default client island from the declared fields
- `restful_controller_with_params(...)` lets generic resources opt into Rails-style strong params without hardcoded `title/body/slug`
- Example type generation now emits typed server action helpers in addition to typed route helpers, so route params and mutation inputs can share one generated surface

## Fifth batch added here

- The migration layer now has a chainable `migration_plan(...)` builder for Rails-like, concise schema changes
- Migration steps now cover opinionated `add_reference`, phased `add_timestamps`, concurrent index add/remove, column rename, default change, and nullability tightening
- `analyze_migration(...)`, `migration_risk_level(...)`, and `migration_safety_summary(...)` add a Strong Migrations-style safety pass so deploy-hostile steps are surfaced early
- The ORM example and tutorial now show the phased nullable/backfill/default/index pattern instead of only raw create-table output

## Sixth batch added here

- `DirtyRecord` and `DirtyFieldChange` now model Active Record-style change tracking against explicit record snapshots
- `dirty_record(...)`, `dirty_new_record(...)`, and `Record::track_changes(...)` surface field-level diffs such as added, removed, and updated attributes
- The in-memory adapter now includes a transaction surface with `begin_transaction(...)`, savepoints, rollback, commit, and validation-aware `transaction_save(...)`
- Public tests now lock in savepoint rollback behavior and dirty-state reset semantics

## Biggest gaps still open

- `activesupport`: concern/autoloading/deprecation/timezones/notifications subscribers
- `activemodel`: typed attributes/serialization/validator objects
- `activerecord`: query interface/scopes/callback chains/database adapters
- `actionpack`: cookies/session store/responders/after_action/around_action/request forgery strategy
- `actionview`: partials/helpers/form builders/template lookup
- `activejob`: adapters/serialization
- `actioncable`: connection lifecycle and richer subscription adapters
- `railties`: generators/initializers/config loading/engines

## Recommended next batches

1. Add `after_action` and `around_action` style controller callbacks.
2. Add partial rendering plus a small helper/form-builder layer so the scaffolded frontend can become less template-string-heavy.
3. Expand the validation library with reusable validator objects and richer message customization.
4. Add Active Job adapters and serialization contracts.
