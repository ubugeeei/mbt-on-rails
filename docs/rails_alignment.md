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

## Seventh batch added here

- The relation builder now supports `distinct_records`, `group_by`, `having_raw`, `reorder_by`, `reverse_order`, `merge_relation`, `pluck_sql`, `exists_sql`, and `none_relation`
- `ModelSchema` now carries named `scope(...)` definitions, with `with_scope(...)` and `find_scope(...)` for reuse
- Public relation tests now cover grouped SQL, merged scopes, and existence/pluck rendering

## Eighth batch added here

- The controller DSL now carries `after_action` and `around_action` style callback metadata in addition to `before_action`
- `controller_summary(...)` renders before/around/after callback declarations so generated plans stay inspectable
- The demo app and public tests now show controller callback metadata alongside action plans

## Ninth batch added here

- The view layer now exposes Rails-style `partial(...)`, `render_partial(...)`, and `with_partial(...)` aliases on top of explicit template imports
- Page modules can now carry typed `form_builder(...)` metadata with field descriptors such as `email_field`, `password_field`, `text_field`, and `textarea_field`
- `render_page(...)` now emits a form-builder manifest so page HTML can ship richer end-to-end UI metadata alongside action and component manifests

## Tenth batch added here

- The validation layer now has reusable `validator(...)` objects that can be attached with `FieldSchema::apply_validator(...)`
- Custom validation messages now interpolate placeholders such as `%{minimum}`, `%{pattern}`, `%{attribute}`, and `%{validator}`
- Active Record models can now bridge reusable validators with `validates_with(...)` in addition to raw `validates(...)`

## Eleventh batch added here

- The Active Job layer now has explicit adapter contracts such as `inline_adapter()`, `async_adapter()`, `test_adapter()`, and `solid_queue_adapter()`
- Jobs now retain their argument type contract after enqueue, so serialized envelopes can round-trip that metadata
- `serialize_job(...)`, `render_serialized_job(...)`, `deserialize_payload(...)`, and `restore_enqueued_job(...)` add explicit serialization contracts for queue backends and persistence

## Twelfth batch added here

- The view layer now exposes `tag(...)` and `content_tag(...)` as concise Action View-style HTML primitives
- `link_to(...)`, `button_to(...)`, and `image_tag(...)` now cover the most common helper-driven template fragments
- `class_names(...)`, `safe_join(...)`, `dom_id(...)`, and `pluralize(...)` keep `.mbtv` call sites compact without giving up typed, explicit inputs

## Thirteenth batch added here

- The Vapor-facing view layer now carries richer `prop_contract(...)`, `emit_contract(...)`, `slot_contract(...)`, and `template_ref_contract(...)` metadata
- Component manifests now expose Vapor Moon-style `scope_id`, `client_module_path`, prop defaults, binding names, emits, slots, and template refs
- Runtime helpers such as `make_scope_id(...)`, `client_module_path(...)`, `scope_css(...)`, `show_style(...)`, `merge_class_names(...)`, `merge_styles(...)`, `use_id(...)`, and `use_template_ref(...)` now mirror Vapor Moon's current helper surface more directly

## Biggest gaps still open

- `activesupport`: concern/autoloading/deprecation/timezones/notifications subscribers
- `activemodel`: typed attributes/serialization
- `activerecord`: callback chains/database adapters/query execution
- `actionpack`: cookies/session store/responders/request forgery strategy
- `actionview`: helper breadth/template lookup
- `activejob`: execution backends/monitoring depth
- `actioncable`: connection lifecycle and richer subscription adapters
- `railties`: generators/initializers/config loading/engines

## Recommended next batches

1. Add typed attribute/serialization support on top of the validation layer.
2. Add deeper Active Job execution backend and monitoring behavior.
3. Add broader Vapor Moon compile/tooling integration instead of only runtime-compatible metadata.
