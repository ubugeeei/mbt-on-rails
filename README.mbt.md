# mbt on rails

`mbt on rails` is a MoonBit-first framework scaffold that aims to feel like Ruby on Rails while keeping the client-server boundary friendly to `vapor-moon` and `luna` style UI authoring.

All implementation code now lives under `src/`, with the repository root exposing a small public facade and tests. Each maintained source file is also kept within 300 lines so the framework stays easy to navigate.

## What is implemented

- Railway-style MVC primitives
  - request/response types
  - Rails-like route recognition
  - `resources`, `scope`, and `namespace` style route DSL
  - controller action plans, before-actions, auth gates, redirects, flashes, and response formats
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
- Vapor Moon compatible frontend boundary
  - `.mbtv` page and component examples under `examples/`
  - layouts and loaders
  - server component references
  - island hydration metadata
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

- [`src/support/support.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/support/support.mbt): shared helpers
- [`src/http/types.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/http/types.mbt), [`src/http/resources.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/http/resources.mbt), [`src/http/matching.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/http/matching.mbt): routing, matching, responses, resource DSL
- [`src/controller/types.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/controller/types.mbt), [`src/controller/restful.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/controller/restful.mbt): controller plans, filters, action steps, response formats
- [`src/auth/types.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/auth/types.mbt), [`src/auth/session.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/auth/session.mbt), [`src/auth/policy.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/auth/policy.mbt): authentication, sessions, policies, cookies, CSRF helpers
- [`src/active_record/schema.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/active_record/schema.mbt), [`src/active_record/relation.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/active_record/relation.mbt), [`src/active_record/sql.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/active_record/sql.mbt), [`src/active_record/memory.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/active_record/memory.mbt): model, relation, SQL, validation, memory DB
- [`src/migration/migration.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/migration/migration.mbt): migration generation and rollback SQL
- [`src/view/types.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/view/types.mbt), [`src/view/builders.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/view/builders.mbt), [`src/view/render.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/view/render.mbt), [`src/view/manifest.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/view/manifest.mbt): server components, SSR shell, hydration metadata, manifests
- [`src/generator/generator.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/generator/generator.mbt): scaffold planner
- [`src/app/types.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/app/types.mbt), [`src/app/runtime.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/app/runtime.mbt), [`src/app/demo_blog.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/app/demo_blog.mbt): integrated demo application and runtime
- [`src/view/assets/hydrate.js`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/src/view/assets/hydrate.js): small client bridge source
- [`mbt_on_rails.mbt`](/Users/ubugeeei/Source/github.com/ubugeeei/mbt-on-rails/mbt_on_rails.mbt): public facade over the `src/*` packages

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
- island hydration metadata
- a small client bridge script
