# Part 6: Views, Layouts, and Templates

## Goal

Understand how pages and layouts are described, and how `.mbtv` templates are tied into the app.

## Key Files

- [`../../src/view/types.mbt`](../../src/view/types.mbt)
- [`../../src/view/page_builders.mbt`](../../src/view/page_builders.mbt)
- [`../../src/view/component_builders.mbt`](../../src/view/component_builders.mbt)
- [`../../src/view/template_validation.mbt`](../../src/view/template_validation.mbt)
- [`../../examples/demo_blog/views`](../../examples/demo_blog/views)

## Page Modules

A page is a typed value:

```moonbit
let page = page_module(
  route_name="posts_show",
  route_path="/posts/[id]",
  file_path=mbtv_path("examples/demo_blog/views/pages/posts/show.mbtv"),
  title="Post",
  component=server_component(
    name="PostsShowPage",
    source_path=mbtv_path("examples/demo_blog/views/pages/posts/show.mbtv"),
    props=[],
  ),
)
```

Then decorate it with:

- `.with_layout(...)`
- `.with_loader(...)`
- `.with_action_name(...)`
- `.with_dynamic_mode(...)`
- `.with_metadata(...)`

## Explicit Template Imports

When a component is used from a template, the template must import it explicitly.
This is enforced by the validator in [`../../src/view/template_validation.mbt`](../../src/view/template_validation.mbt).

That means template composition stays:

- explicit
- analyzable
- safer for code generation

## Generated Typed Helpers

The repository generates helper functions for:

- template paths
- route params
- route path builders

Read:

- [`../../cmd/generate_example_types/main.mbt`](../../cmd/generate_example_types/main.mbt)
- [`../../examples/demo_blog/generated_types.mbt`](../../examples/demo_blog/generated_types.mbt)

## Exercise

- Open one page template under [`../../examples/demo_blog/views/pages`](../../examples/demo_blog/views/pages)
- Find the imported components
- Compare them with the mounted/imported components declared from MoonBit

## Next

Continue to [Part 7: Client-Server Boundaries](part_07_client_server_boundaries.md).
