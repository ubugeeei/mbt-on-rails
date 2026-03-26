# Part 9: Jobs, Mailers, Cache, and Notifications

## Goal

Learn the runtime helper layers that support background work and observability.

## Key Files

- [`../../src/job/types.mbt`](../../src/job/types.mbt)
- [`../../src/job/queue.mbt`](../../src/job/queue.mbt)
- [`../../src/mailer/types.mbt`](../../src/mailer/types.mbt)
- [`../../src/mailer/delivery.mbt`](../../src/mailer/delivery.mbt)
- [`../../src/cache/types.mbt`](../../src/cache/types.mbt)
- [`../../src/cache/store.mbt`](../../src/cache/store.mbt)
- [`../../src/support/notifications.mbt`](../../src/support/notifications.mbt)

## Jobs

The current job layer models:

- job definitions
- enqueued jobs
- ready-vs-waiting queues
- retry limits

Helpers include:

- `enqueue_now`
- `enqueue_at`
- `drain_ready`
- `retry_job`

## Mailers

Mailers are typed descriptors:

- `mailer(...)`
- `mail_template(...)`
- `compose_mail(...)`
- `enqueue_delivery(...)`

This keeps email handling easy to test in pure data form.

## Cache

Cache helpers model:

- write-through values
- read-through fetch
- tags
- explicit delete/delete-by-tag behavior

## Rails-Style Notifications

This repository now includes a first-pass notification layer inspired by `ActiveSupport::Notifications`.

Current event names include:

- `start_processing.action_controller`
- `process_action.action_controller`
- `render_template.action_view`
- `render_layout.action_view`
- `cache_read.active_support`
- `cache_generate.active_support`
- `cache_write.active_support`
- `enqueue.active_job`
- `enqueue_at.active_job`
- `enqueue_retry.active_job`
- `process.action_mailer`

See [`../../tests/public/notifications_wbtest.mbt`](../../tests/public/notifications_wbtest.mbt).

## Exercise

- Build a small notification buffer with `notifications()`
- Record a cache fetch or job enqueue
- Print `summary()` and inspect the payloads

## Next

Continue to [Part 10: Cable and Turbo Streams](part_10_cable_and_turbo_streams.md).
