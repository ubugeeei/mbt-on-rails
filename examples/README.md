# Examples

`mbt on rails` ships with small examples under `./examples` so you can see the public API in focused chunks instead of starting from the large demo app.

## Run

```bash
moon run examples/resource_app
moon run examples/orm_migration
moon run examples/auth_policy
moon run examples/rails_ops
moon run examples/production_stack
moon run examples/production_api
moon run examples/process_topology
```

## Included examples

- `examples/demo_blog`
  - The full built-in `demo_blog_app()` example, including MoonBit setup code and `.mbtv` assets.
- `examples/resource_app`
  - A small Notes app built from the public `app`, `resources`, `restful_controller`, `page_module`, and `server_action` APIs.
  - Includes local `.mbtv` files so the example is self-contained.
- `examples/orm_migration`
  - Shows model schema design, relation SQL generation, migration SQL generation, and the in-memory validation flow.
- `examples/auth_policy`
  - Shows identities, sessions, CSRF validation, cookies, direct auth requirements, and policy-rule checks.
- `examples/rails_ops`
  - Shows Strong Parameters, Action Cable, middleware, fixtures/seeds, Active Job, Action Mailer, Turbo Stream, and cache store helpers working together.
- `examples/production_stack`
  - Shows deployment config, health/readiness JSON, rate limiting, and structured logging helpers.
- `examples/production_api`
  - Shows an API-only stack with versioned routes, health/readiness endpoints, Prometheus metrics, JSON API payloads, and secret summaries.
- `examples/process_topology`
  - Shows a Procfile-like deployment topology with web, worker, cable, scheduler, and release tasks.

## Suggested reading order

1. Start with `examples/resource_app/main.mbt` for end-to-end app composition.
2. Read `examples/orm_migration/main.mbt` to understand the data layer.
3. Read `examples/auth_policy/main.mbt` to understand the auth primitives.
4. Read `examples/rails_ops/main.mbt` to understand the Rails-style operational helpers.
5. Read `examples/production_stack/main.mbt` for production-facing runtime helpers.
6. Read `examples/production_api/main.mbt` for API-only production helpers.
7. Read `examples/process_topology/main.mbt` for deployment process planning.
8. Browse `examples/demo_blog/` to see the full demo app, then `examples/demo_blog/views/` for the view and mailer assets it renders.
