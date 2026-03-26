# mbt on rails

`mbt on rails` is a MoonBit-first framework scaffold that aims to feel like Ruby on Rails while keeping the client-server boundary friendly to `vapor-moon` and `luna` style UI authoring.

All implementation code now lives under `src/`, with the repository root exposing a small public facade and tests. Each maintained source file is also kept within 300 lines so the framework stays easy to navigate.

## What is implemented

- Railway-style MVC primitives
  - request/response types
  - Rails-like route recognition
  - `resources`, `scope`, and `namespace` style route DSL
  - controller action plans, before-actions, auth gates, Strong Parameters steps, redirects, flashes, background jobs, cache touches, and response formats
  - Rack-style middleware stack
- Active Record style backend primitives
  - model schema DSL
  - associations
  - validations
  - lifecycle callbacks
  - relation builder
  - SQL generation for `SELECT`, `INSERT`, `UPDATE`, `DELETE`, and `UPSERT`
  - in-memory adapter for simple records and validation checks
- Migration system
  - create/alter/drop steps
  - reversible migrations
  - schema SQL generation
  - index generation
  - rollback SQL generation
- Authentication and authorization
  - session issuing
  - password digest placeholder
  - password reset and email verification token issuing
  - role and permission checks
  - policy rules
  - CSRF helpers
  - cookie helpers
- Rails operational primitives
  - Strong Parameters-style filtering
  - Active Job-style queues, retries, and drain helpers
  - Action Cable-style channel and broadcast descriptors
  - Action Mailer-style templates, composed deliveries, and queue integration
  - cache store helpers with namespaced keys, tags, and read-through fetch
  - fixture loading and `db:seed` style plans
  - Turbo Stream response rendering
  - deployment config, health/readiness JSON, rate limiting, and structured logging
  - Prometheus-style metrics and secret masking helpers
  - JSON API style response helpers for API-only surfaces
  - Procfile-like process and release task descriptors
- Vapor Moon compatible frontend boundary
  - `.mbtv` page and component examples under `examples/`
  - layouts and loaders
  - server component references
  - explicit server/client contracts with JSON-only prop schemas
  - island hydration metadata
  - SSR fallback HTML for islands
  - form bindings
  - server action manifest
  - route tree and page-router manifest
  - SSR shell generation with hydration payloads
- App generation helpers
  - scaffold planning for resource-oriented apps
  - integrated demo blog app with auth, posts resource, server actions, SSR pages, and migrations

## Important note about vapor-moon integration

As of 2026-03-23, `ubugeeei/vapor_moon` was not available from the MoonBit registry in this environment, so this repository uses a compatibility approach instead of a direct registry dependency:

- `.mbtv` files are included under `examples/demo_blog/views/` and other `examples/*/views/` directories
- hydration modes mirror Vapor Moon directives such as `client:load`, `client:visible`, `client:idle`, and `server:defer`
- page rendering emits manifest and placeholder attributes that a real Vapor Moon runtime can consume later
- the small client bridge source lives at `src/view/assets/hydrate.js`, while rendered pages reference it through `/assets/hydrate.js`

That keeps the current codebase buildable while preserving the intended interface.

## Layout

- [`src/support/collections.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/support/collections.mbt), [`src/support/pathing.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/support/pathing.mbt), [`src/support/json.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/support/json.mbt), [`src/support/encoding.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/support/encoding.mbt), [`src/support/naming.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/support/naming.mbt): shared helpers split by collection, path, JSON, encoding, and naming concerns
- [`src/http/types.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/http/types.mbt), [`src/http/resources.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/http/resources.mbt), [`src/http/matching.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/http/matching.mbt): routing, matching, responses, resource DSL
- [`src/controller/types.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/controller/types.mbt), [`src/controller/restful.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/controller/restful.mbt): controller plans, filters, action steps, response formats
- [`src/auth/types.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/auth/types.mbt), [`src/auth/session.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/auth/session.mbt), [`src/auth/policy.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/auth/policy.mbt): authentication, sessions, policies, cookies, CSRF helpers
- [`src/active_record/schema.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/active_record/schema.mbt), [`src/active_record/relation.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/active_record/relation.mbt), [`src/active_record/sql.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/active_record/sql.mbt), [`src/active_record/memory.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/active_record/memory.mbt): model, relation, SQL, validation, memory DB
- [`src/migration/migration.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/migration/migration.mbt): migration generation and rollback SQL
- [`src/params/types.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/params/types.mbt), [`src/params/filtering.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/params/filtering.mbt): Strong Parameters-style filtering
- [`src/middleware/types.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/middleware/types.mbt), [`src/middleware/runtime.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/middleware/runtime.mbt): Rack-style middleware layers and runtime application
- [`src/fixture/types.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/fixture/types.mbt), [`src/fixture/load.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/fixture/load.mbt): fixtures and seed plans
- [`src/cable/channel.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/cable/channel.mbt), [`src/cable/summary.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/cable/summary.mbt): Action Cable-style channels and Turbo Stream broadcasts
- [`src/job/types.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/job/types.mbt), [`src/job/queue.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/job/queue.mbt): Active Job-style queueing and retries
- [`src/mailer/types.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/mailer/types.mbt), [`src/mailer/delivery.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/mailer/delivery.mbt): Action Mailer-style templates and deliveries
- [`src/cache/types.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/cache/types.mbt), [`src/cache/store.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/cache/store.mbt): cache stores, tags, and read-through fetch helpers
- [`src/turbo/stream.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/turbo/stream.mbt): Turbo Stream rendering helpers
- [`src/production/types.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/production/types.mbt), [`src/production/render.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/production/render.mbt): deployment config, health probes, rate limiting, and JSON logs
- [`src/production/http.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/production/http.mbt): health/readiness responses, metrics responses, and JSON API helpers
- [`src/metrics/types.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/metrics/types.mbt), [`src/metrics/render.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/metrics/render.mbt): Prometheus-style metrics registry helpers
- [`src/secrets/types.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/secrets/types.mbt), [`src/secrets/render.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/secrets/render.mbt): secret contracts, masking, and validation
- [`src/process/types.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/process/types.mbt), [`src/process/render.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/process/render.mbt): deploy process topology and release task helpers
- [`src/view/types.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/view/types.mbt), [`src/view/component_builders.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/view/component_builders.mbt), [`src/view/page_builders.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/view/page_builders.mbt), [`src/view/modes.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/view/modes.mbt), [`src/view/contracts.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/view/contracts.mbt), [`src/view/render.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/view/render.mbt), [`src/view/manifest.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/view/manifest.mbt): server components, page builders, hydration modes, server/client contracts, SSR shell, and manifests
- [`src/generator/generator.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/generator/generator.mbt): scaffold planner
- [`src/app/types.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/app/types.mbt), [`src/app/runtime.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/app/runtime.mbt), [`examples/demo_blog/app.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/examples/demo_blog/app.mbt): generic app runtime plus the integrated demo application now kept under `examples/demo_blog/`
- [`src/view/assets/hydrate.js`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/view/assets/hydrate.js): small client bridge source
- [`mbt_on_rails.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/mbt_on_rails.mbt), [`mbt_on_rails_modeling.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/mbt_on_rails_modeling.mbt), [`mbt_on_rails_web.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/mbt_on_rails_web.mbt): public facade files over the `src/*` packages

## Commands

```bash
moon build
moon test
moon run cmd/main
```

## Examples

See [`examples/README.md`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/examples/README.md) for focused, runnable examples:

- `moon run examples/resource_app`
- `moon run examples/orm_migration`
- `moon run examples/auth_policy`
- `moon run examples/rails_ops`
- `moon run examples/production_stack`
- `moon run examples/production_api`
- `moon run examples/process_topology`
- built-in demo blog view assets: [`examples/demo_blog/README.md`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/examples/demo_blog/README.md)

## Example API

```moonbit nocheck
///|
let app = demo_blog_app()

///|
let response = handle_request(
  app,
  request(http_get(), "/posts/42", [], [], None, ""),
)
```

This returns a rendered SSR HTML shell for the `posts_show` page and includes:

- route data
- server action manifest
- component contract manifest
- island hydration metadata
- a small client bridge script

## Declarative builder style

The public DSL also supports method chaining so app/controller/page setup can stay flat instead of turning into nested `with_*` calls:

```moonbit nocheck
///|
let sessions = action_plan("create")
  .require_auth(auth_guest_only())
  .permit_params(["email", "password"])
  .invoke_server_action("sessions.create")
  .redirect_to("/")
  .json()
  .as_mutation()
  .as_transactional()

///|
let controller = controller_named("SessionsController")
  .for_resource("sessions")
  .with_before_action(
    before_only("create")
      .requiring(auth_guest_only())
      .permitting(["email", "password"]),
  )
  .with_action(sessions)

///|
let app = app_named("notes example")
  .with_controller(controller)
  .with_pages(note_pages(layout))
  .with_server_actions(note_server_actions())
```
