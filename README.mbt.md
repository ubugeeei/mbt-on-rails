# mbt on rails

`mbt on rails` is a MoonBit-first, Rails-inspired framework skeleton.
It focuses on a declarative API, typed route/model helpers, and an explicit client-server boundary for `.mbtv` templates.

## Quick Start

```bash
moon test
moon run examples/resource_app
moon run examples/demo_blog
```

## Read This First

- [Tutorial](docs/tutorial/README.md)
  - A full Rails Tutorial-style walkthrough for this repository.
- [Examples](examples/README.md)
  - Small runnable apps and focused feature demos.
- [Rails Alignment](docs/rails_alignment.md)
  - What is already implemented and what still separates this project from Rails itself.

## What You Get

- Routing with `resources`, `scope`, and `namespace`
- Declarative controllers, before/after/around callback metadata, and action plans
- Active Record-style schema, scopes, relations, reusable validators, update-aware persistence, dirty tracking, in-memory transactions, and opinionated migration plans with safety analysis
- Auth, signed cookies, request/session helpers, session-store builders, policies, and CSRF helpers
- `.mbtv` pages, layouts, partials, Action View-style HTML helpers, server components, client islands, and suspense-like boundaries
- Server actions, form bindings, typed form builders, and generated typed route/action helpers
- Vapor Moon-compatible scope ids, client module paths, template refs, and prop/emit/slot metadata
- Jobs, adapter contracts, serialized job envelopes, mailers, cache, cable, turbo stream, and production helpers
- Rails-style runtime notifications for controller, view, cache, job, and mailer flows

## Main Entry Points

- [mbt_on_rails.mbt](mbt_on_rails.mbt)
  - Public facade.
- [examples/resource_app](examples/resource_app)
  - Smallest end-to-end app.
- [examples/demo_blog](examples/demo_blog)
  - Richer integrated example.
- [tests/public](tests/public)
  - Public API whitebox tests.

## Repository Shape

- `src/`
  - Framework implementation.
- `examples/`
  - Runnable apps and demos.
- `docs/tutorial/`
  - Tutorial parts.
- `tests/public/`
  - Public-surface tests.

## Notes

- The root is intentionally thin: one public facade plus package metadata.
- `.mbtv` component usage requires explicit template imports.
- Demo/helper code generation is implemented in MoonBit, not Python.
