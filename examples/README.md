# Examples

`mbt on rails` ships with small examples under `./examples` so you can see the public API in focused chunks instead of starting from the large demo app.

## Run

```bash
moon run examples/resource_app
moon run examples/orm_migration
moon run examples/auth_policy
moon run examples/rails_ops
```

## Included examples

- `examples/demo_blog`
  - The `.mbtv` assets used by the built-in `demo_blog_app()` that powers `moon run cmd/main`.
- `examples/resource_app`
  - A small Notes app built from the public `app`, `resources`, `restful_controller`, `page_module`, and `server_action` APIs.
  - Includes local `.mbtv` files so the example is self-contained.
- `examples/orm_migration`
  - Shows model schema design, relation SQL generation, migration SQL generation, and the in-memory validation flow.
- `examples/auth_policy`
  - Shows identities, sessions, CSRF validation, cookies, direct auth requirements, and policy-rule checks.
- `examples/rails_ops`
  - Shows Strong Parameters, Action Cable, middleware, fixtures/seeds, Active Job, Action Mailer, Turbo Stream, and cache store helpers working together.

## Suggested reading order

1. Start with `examples/resource_app/main.mbt` for end-to-end app composition.
2. Read `examples/orm_migration/main.mbt` to understand the data layer.
3. Read `examples/auth_policy/main.mbt` to understand the auth primitives.
4. Read `examples/rails_ops/main.mbt` to understand the Rails-style operational helpers.
5. Browse `examples/demo_blog/views/` to see the view and mailer assets used by `demo_blog_app()`.
