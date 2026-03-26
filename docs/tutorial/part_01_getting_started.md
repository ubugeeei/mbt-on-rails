# Part 1: Getting Started

## Goal

Build a mental model for the repository before touching individual features.

## What `mbt on rails` Is

`mbt on rails` is a MoonBit framework skeleton with Rails-like naming and composition:

- router DSL
- controller DSL
- Active Record-style schema and relation helpers
- `.mbtv` view modules
- explicit client-server contracts
- operations helpers for jobs, cache, mailer, cable, and production

The core public API is re-exported from [`../../mbt_on_rails.mbt`](../../mbt_on_rails.mbt).

## Start With These Commands

```bash
moon test
moon run examples/resource_app
moon run examples/demo_blog
```

`moon test` is the fastest way to see the framework surface in action.

## Learn The Repository Shape

- [`../../src`](../../src)
  - framework implementation
- [`../../examples`](../../examples)
  - runnable apps
- [`../../tests/public`](../../tests/public)
  - public-surface tests
- [`../rails_alignment.md`](../rails_alignment.md)
  - current gap map against Rails

## Your First App Shape

The smallest useful mental model is:

1. define models
2. define routes
3. define controllers
4. define pages and server actions
5. compose everything into `app_named(...)`

You can see that shape in [`../../examples/resource_app/app.mbt`](../../examples/resource_app/app.mbt).

## First Reading Pass

Read these files in order:

1. [`../../examples/resource_app/app.mbt`](../../examples/resource_app/app.mbt)
2. [`../../examples/resource_app/frontend.mbt`](../../examples/resource_app/frontend.mbt)
3. [`../../examples/resource_app/schema.mbt`](../../examples/resource_app/schema.mbt)
4. [`../../examples/resource_app/views`](../../examples/resource_app/views)

## A Tiny Example

```moonbit
let app = app_named("notes")
  .with_routes(note_routes())
  .with_controllers(note_controllers())
  .with_pages(note_pages(layout))
```

That flat, chainable style is the default style this repository is moving toward.

## Exercise

- Run `moon run examples/resource_app`
- Find one route, one controller action, and one page in the output
- Trace each of them back to source

## Next

Continue to [Part 2: Routes and Controllers](part_02_routes_and_controllers.md).
