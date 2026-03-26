# Part 12: Scaffolds, Testing, and Next Steps

## Goal

Finish the tutorial by understanding generation, tests, and the roadmap.

## Key Files

- [`../../src/generator/generator.mbt`](../../src/generator/generator.mbt)
- [`../../src/generator/example_types.mbt`](../../src/generator/example_types.mbt)
- [`../../cmd/generate_example_types/main.mbt`](../../cmd/generate_example_types/main.mbt)
- [`../../tests/public`](../../tests/public)
- [`../rails_alignment.md`](../rails_alignment.md)

## Scaffolds

The scaffold layer can already generate plans for resource-oriented apps:

- model artifact ideas
- controller/action shapes
- route sets
- view file locations

Read:

- [`../../examples/scaffold`](../../examples/scaffold)
- [`../../tests/public/view_wbtest.mbt`](../../tests/public/view_wbtest.mbt)

## Typed Helper Generation

The example type generator is written in MoonBit.
It extracts:

- typed template helper functions
- typed route param structs
- typed route path helpers

Run it with:

```bash
moon run --target native cmd/generate_example_types -- <package_dir> <frontend_path> <output_path>
```

## Tests

`tests/public` is the best place to study the public API surface.

Recommended order:

1. `core_wbtest`
2. `http_edges_wbtest`
3. `view_wbtest`
4. `notifications_wbtest`
5. `production_wbtest`

## Where The Project Still Needs Work

The largest gaps versus Rails are still:

- Active Model-style errors/typed attributes
- Active Record transactions and dirty tracking
- controller `after_action` and `around_action`
- helpers, partials, and form builders
- job adapters and retry policies
- railties/generator/initializer depth

Track that in [`../rails_alignment.md`](../rails_alignment.md).

## After The Tutorial

A good next project is:

1. fork `examples/resource_app`
2. add auth
3. add one client island
4. add one background job
5. add one production health endpoint

At that point you will have touched almost every major subsystem in the repo.
