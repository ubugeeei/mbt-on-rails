# Part 11: Production and Operations

## Goal

Understand the production-facing helper surface.

## Key Files

- [`../../src/production/types.mbt`](../../src/production/types.mbt)
- [`../../src/production/render.mbt`](../../src/production/render.mbt)
- [`../../src/production/http.mbt`](../../src/production/http.mbt)
- [`../../src/metrics/types.mbt`](../../src/metrics/types.mbt)
- [`../../src/secrets/types.mbt`](../../src/secrets/types.mbt)
- [`../../src/process/types.mbt`](../../src/process/types.mbt)

## Production Config

The framework already models:

- environments
- deployment config
- health checks
- readiness checks
- rate limits
- structured logs

## Observability

You can also describe:

- counters and gauges
- metrics registries
- Prometheus rendering
- secret validation and masking

This makes examples like [`../../examples/production_api/main.mbt`](../../examples/production_api/main.mbt) and [`../../examples/production_stack/main.mbt`](../../examples/production_stack/main.mbt) useful without needing a full deployment runtime.

## Process Topology

The `process` package covers:

- web processes
- workers
- cable processes
- scheduler processes
- release tasks

See [`../../examples/process_topology/main.mbt`](../../examples/process_topology/main.mbt).

## Exercise

- Run `moon run examples/production_api`
- Find the health output, metrics output, and secrets summary
- Then open the source and find the corresponding helper calls

## Next

Continue to [Part 12: Scaffolds, Testing, and Next Steps](part_12_scaffolds_testing_and_next_steps.md).
