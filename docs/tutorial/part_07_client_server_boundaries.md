# Part 7: Client-Server Boundaries

## Goal

Learn the explicit boundary model between server components and client components.

## Key Files

- [`../../src/view/contracts.mbt`](../../src/view/contracts.mbt)
- [`../../src/view/composition.mbt`](../../src/view/composition.mbt)
- [`../../src/view/runtime_compat.mbt`](../../src/view/runtime_compat.mbt)
- [`../../src/view/manifest.mbt`](../../src/view/manifest.mbt)
- [`../../examples/demo_blog/contracts.mbt`](../../examples/demo_blog/contracts.mbt)

## Boundary Model

Components declare a contract:

- `server_contract(props=..., async_only=...)`
- `client_contract(...)`
- `prop_contract(name=..., type_name=..., required=..., description=..., default_value=...)`
- `emit_contract(name=..., signature=...)`
- `slot_contract(name=..., signature=...)`
- `template_ref_contract(ref_name=..., binding_name=...)`

Props are described as JSON-serializable contracts.
That is the current safety boundary of the framework.
The manifest can now also carry:

- prop defaults
- props/emits/slots binding names
- typed emits and slots
- template refs declared by the compiled component
- Vapor Moon-style `scope_id` and `client_module_path`

## Import And Mount

Server components can embed imported client components through:

- `template_import(...)`
- `mount_import(...)`
- `with_template_import(...)`
- `with_child(...)`

This gives you an RSC-like structure without hiding the boundary.

## Suspense-Like Nodes

The repository also includes a suspense-style node:

- `suspense_boundary(...)`

This is currently structural metadata plus SSR placeholder rendering.
It is designed so later runtime work can make the boundary smarter without changing the authoring shape.

## Runtime Compatibility

To stay closer to modern Vapor Moon, the view package also exposes runtime-facing
helpers:

- `make_scope_id(...)`
- `client_module_path(...)`
- `scope_css(...)`
- `show_style(...)`
- `merge_class_names(...)`
- `merge_styles(...)`
- `use_id(...)`
- `use_template_ref(...)`

## Why This Design

The repo intentionally avoids a magic boundary.
Instead it prefers:

- explicit imports
- explicit contracts
- explicit mounted children

That makes code generation and validation much easier.

## Exercise

- Read [`../../examples/demo_blog/contracts.mbt`](../../examples/demo_blog/contracts.mbt)
- Find one client island contract and one server component contract
- Trace how each appears in the rendered manifest

## Next

Continue to [Part 8: Server Actions and Forms](part_08_server_actions_and_forms.md).
