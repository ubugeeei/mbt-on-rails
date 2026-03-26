# Part 2: Routes and Controllers

## Goal

Understand how requests are described and how controller intent is modeled.

## Key Files

- [`../../src/http/types.mbt`](../../src/http/types.mbt)
- [`../../src/http/resources.mbt`](../../src/http/resources.mbt)
- [`../../src/http/matching.mbt`](../../src/http/matching.mbt)
- [`../../src/controller/types.mbt`](../../src/controller/types.mbt)
- [`../../src/controller/builders.mbt`](../../src/controller/builders.mbt)
- [`../../src/controller/restful.mbt`](../../src/controller/restful.mbt)

## The Routing Layer

Routes are plain typed values:

- `route(...)`
- `resources(...)`
- `scope_routes(...)`
- `namespace_routes(...)`

Example:

```moonbit
let routes = resources(
  resource_name="notes",
  controller="NotesController",
  options=default_resource_options("notes", Some("notes")),
)
```

The repository also generates typed path helpers for view-facing routes.
See [`../../examples/resource_app/generated_types.mbt`](../../examples/resource_app/generated_types.mbt).

## Route Recognition

Incoming requests are represented by `request(verb=..., path=..., ...)`.
Matching happens through `recognize(...)`.

The public tests in [`../../tests/public/http_edges_wbtest.mbt`](../../tests/public/http_edges_wbtest.mbt) are a good guide for dynamic segments, catch-all segments, and resource routes.

## Controllers Are Plans

Unlike classic Rails, this repository models controller behavior as data:

- `before_only(...)`
- `after_only(...)`
- `around_each(...)`
- `action_plan(...)`
- `require_auth(...)`
- `permit_params(...)`
- `invoke_server_action(...)`
- `redirect_to(...)`

Example:

```moonbit
let controller = controller_named("SessionsController")
  .for_resource("sessions")
  .with_around_action(around_each().running("with_request_store"))
  .with_after_action(after_only("create").running("audit_session"))
  .with_action(
    action_plan("create")
      .require_auth(auth_guest_only())
      .permit_params(["email", "password"])
      .invoke_server_action("sessions.create")
      .redirect_to("/"),
  )
```

## Why This Matters

This makes the controller layer:

- flatter
- easier to inspect
- easier to generate
- easier to validate
- closer to Rails-style callback metadata without hiding behavior in macros

## Exercise

- Open [`../../examples/demo_blog/controllers.mbt`](../../examples/demo_blog/controllers.mbt)
- Find one action that is transactional
- Find one action that redirects
- Find one action that requires auth

## Next

Continue to [Part 3: Models and Migrations](part_03_models_and_migrations.md).
