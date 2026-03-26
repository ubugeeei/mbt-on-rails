# Part 6: Views, Layouts, and Templates

## Goal

Understand how pages and layouts are described, and how `.mbtv` templates are tied into the app.

## Key Files

- [`../../src/view/types.mbt`](../../src/view/types.mbt)
- [`../../src/view/page_builders.mbt`](../../src/view/page_builders.mbt)
- [`../../src/view/component_builders.mbt`](../../src/view/component_builders.mbt)
- [`../../src/view/helpers.mbt`](../../src/view/helpers.mbt)
- [`../../src/view/composition.mbt`](../../src/view/composition.mbt)
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
- `.with_partial(partial(...))`

Favor labeled arguments for builders like `page_module(...)` so route names,
paths, and titles stay readable at a glance.

## Explicit Template Imports

When a component is used from a template, the template must import it explicitly.
This is enforced by the validator in [`../../src/view/template_validation.mbt`](../../src/view/template_validation.mbt).

That means template composition stays:

- explicit
- analyzable
- safer for code generation

Rails-style partial naming is now available as a thin alias over those same primitives:

```moonbit
let page_component = server_component(
  name="SignInPage",
  source_path=view_pages_sign_in(),
  props=[],
)
.with_partial(
  partial(
    local_name="SignInForm",
    component=server_component(
      name="SignInForm",
      source_path=view_components_sign_in_form(),
      props=[],
    ),
  ),
)
.with_child(render_partial(name="SignInForm", locals=[]))
```

## Helper Layer

The view package now also exposes a small Action View-style helper layer for
HTML fragments that still stays explicit in MoonBit:

```moonbit
let navigation = content_tag(
  name="nav",
  content=safe_join(
    [
      link_to(label="Posts", href="/posts"),
      button_to(label="Delete", action="/posts/42", http_method="delete"),
    ],
    separator=" ",
  ),
  attrs=[("id", dom_id(record_name="posts", record_id=Some("42")))],
  escape=false,
)
```

The core helpers are:

- `tag(...)`
- `content_tag(...)`
- `link_to(...)`
- `button_to(...)`
- `image_tag(...)`
- `class_names(...)`
- `safe_join(...)`
- `dom_id(...)`
- `pluralize(...)`

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
