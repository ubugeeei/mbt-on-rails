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
- generated typed mutation helpers from `generated_types.mbt`

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

The generator now also emits typed action helpers:

```moonbit
let input = posts_create_action_input(
  title="Hello",
  slug="hello",
  body="Typed all the way down",
)
let entries = posts_create_action_entries(input)
```

This is the current end-to-end type-safe path for routes plus mutations in the codebase.

Builder-style APIs like `server_action(...)` and `request(...)` read best with
labeled arguments, especially once booleans show up in the call site.

## Exercise

- Open [`../../examples/resource_app/generated_types.mbt`](../../examples/resource_app/generated_types.mbt)
- Find `notes_show_route_params`
- Find one `*_action_input(...)` helper
- Trace how both can be used to prepare a request without stringly-typed field names

## Next

Continue to [Part 9: Jobs, Mailers, Cache, and Notifications](part_09_jobs_mailers_cache_and_notifications.md).
