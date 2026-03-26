# Part 10: Cable and Turbo Streams

## Goal

See how realtime-ish UI updates are modeled in the current framework.

## Key Files

- [`../../src/cable/channel.mbt`](../../src/cable/channel.mbt)
- [`../../src/cable/summary.mbt`](../../src/cable/summary.mbt)
- [`../../src/turbo/stream.mbt`](../../src/turbo/stream.mbt)
- [`../../examples/rails_ops/main.mbt`](../../examples/rails_ops/main.mbt)

## Cable

The current cable layer models:

- channel names
- stream names
- topic keys
- broadcasts

Helpers include:

- `cable_channel(...)`
- `cable_broadcast(...)`
- `broadcast_turbo(...)`

## Turbo Streams

Turbo stream helpers include:

- `append_stream`
- `prepend_stream`
- `replace_stream`
- `update_stream`
- `remove_stream`
- `render_turbo_stream`

This is enough to express server-side DOM mutation plans even without a full Rails runtime.

## Current Scope

This part of the framework is intentionally descriptive:

- it gives you typed payloads
- it gives you rendering helpers
- it does not yet give you a full Action Cable server implementation

That is a good example of the overall project philosophy: data-first APIs now, deeper runtime later.

## Exercise

- Open [`../../examples/rails_ops/main.mbt`](../../examples/rails_ops/main.mbt)
- Find where a turbo stream payload is built
- Find where a cable broadcast summary is printed

## Next

Continue to [Part 11: Production and Operations](part_11_production_and_operations.md).
