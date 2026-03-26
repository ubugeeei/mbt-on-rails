# Part 8: Server Actions and Forms

## Goal

Understand how mutations are modeled and how forms connect to them.

## Key Files

- [`../../src/view/component_builders.mbt`](../../src/view/component_builders.mbt)
- [`../../src/view/render.mbt`](../../src/view/render.mbt)
- [`../../examples/demo_blog/frontend.mbt`](../../examples/demo_blog/frontend.mbt)
- [`../../examples/resource_app/frontend.mbt`](../../examples/resource_app/frontend.mbt)

## Server Actions

Actions are declared explicitly:

```moonbit
let create_action = server_action(
  name="posts.create",
  route="/_actions/posts.create",
  input_fields=[("title", "String"), ("body", "String")],
  output_type="PostPayload",
  csrf_protected=true,
)
```

This gives you:

- manifestable input/output contracts
- predictable route names
- explicit CSRF expectations

## Form Bindings

Forms connect page UI to actions through `form_binding(...)`.

Use it to describe:

- action name
- verb
- optimistic key
- redirect target

## Route Helper Generation

Generated helpers make dynamic routes more readable:

```moonbit
let params = posts_show_route_params(id="42")
let path = posts_show_path(params)
```

This is one of the biggest ergonomics wins in the current codebase.

## Exercise

- Open [`../../examples/resource_app/generated_types.mbt`](../../examples/resource_app/generated_types.mbt)
- Find `notes_show_route_params`
- Trace where the generated helper is consumed

## Next

Continue to [Part 9: Jobs, Mailers, Cache, and Notifications](part_09_jobs_mailers_cache_and_notifications.md).
