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

## Biggest gaps still open

- `activesupport`: concern/autoloading/deprecation/timezones/notifications subscribers
- `activemodel`: typed attributes/errors/serialization/validator objects
- `activerecord`: transactions/dirty tracking/query interface/scopes/callback chains
- `actionpack`: cookies/session store/responders/after_action/around_action/request forgery strategy
- `actionview`: partials/helpers/form builders/template lookup
- `activejob`: adapters/serialization/retry_on/discard_on
- `actioncable`: connection lifecycle and richer subscription adapters
- `railties`: generators/initializers/config loading/engines

## Recommended next batches

1. Add `ActiveModel::Errors`-like typed validation results.
2. Add `after_action` and `around_action` style controller callbacks.
3. Add `retry_on` / `discard_on` style job policy structs.
4. Add partial rendering and a small helper/form-builder layer.
