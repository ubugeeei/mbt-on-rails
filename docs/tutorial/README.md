# Tutorial

This is a Rails Tutorial-style walkthrough for `mbt on rails`.
It is not a port of the original Ruby on Rails Tutorial text. Instead, it teaches this repository in the same spirit: start small, build a real app shape, and grow into the full stack.

The examples and `.mbtv` pages in this repository are meant to be read alongside the tutorial, not after it. If something in the tutorial feels abstract, jump into the matching example directory and compare the page modules, controller metadata, and rendered HTML manifests side by side.

## Audience

- You want to learn this repository from top to bottom.
- You want a guided path from routing to production concerns.
- You prefer reading in small parts instead of opening the whole codebase at once.

## Reading Order

1. [Part 1: Getting Started](part_01_getting_started.md)
2. [Part 2: Routes and Controllers](part_02_routes_and_controllers.md)
3. [Part 3: Models and Migrations](part_03_models_and_migrations.md)
4. [Part 4: Validations and Queries](part_04_validations_and_queries.md)
5. [Part 5: Authentication and Authorization](part_05_authentication_and_authorization.md)
6. [Part 6: Views, Layouts, and Templates](part_06_views_layouts_and_templates.md)
7. [Part 7: Client-Server Boundaries](part_07_client_server_boundaries.md)
8. [Part 8: Server Actions and Forms](part_08_server_actions_and_forms.md)
9. [Part 9: Jobs, Mailers, Cache, and Notifications](part_09_jobs_mailers_cache_and_notifications.md)
10. [Part 10: Cable and Turbo Streams](part_10_cable_and_turbo_streams.md)
11. [Part 11: Production and Operations](part_11_production_and_operations.md)
12. [Part 12: Scaffolds, Testing, and Next Steps](part_12_scaffolds_testing_and_next_steps.md)

## Suggested Pace

- Parts 1-4: core backend
- Parts 5-8: application and UI boundary
- Parts 9-11: runtime and operations
- Part 12: generation, tests, and roadmap

## What To Run Alongside The Tutorial

```bash
moon test
moon run examples/resource_app
moon run examples/demo_blog
moon run examples/rails_ops
moon run examples/production_api
```

## Best Reading Loop

- Read one part.
- Run the matching example.
- Open the related files listed in the part.
- Compare the public test that locks the behavior in.

That loop is the fastest way to understand how the API surface, the examples, and the tests line up.

## Main Source Landmarks

- [`../../mbt_on_rails.mbt`](../../mbt_on_rails.mbt)
- [`../../examples/resource_app`](../../examples/resource_app)
- [`../../examples/demo_blog`](../../examples/demo_blog)
- [`../../tests/public`](../../tests/public)
- [`../rails_alignment.md`](../rails_alignment.md)
