///|
/// Re-exports the Vapor-facing view primitives.
pub using @view {
  type AssetManifest,
  type DynamicMode,
  type FormBinding,
  type HydrationMode,
  type LayoutModule,
  type LoaderModule,
  type PageModule,
  type RenderedPage,
  type ServerAction,
  type VaporComponentRef,
  asset_manifest,
  client_component,
  default_assets,
  defer_on_server,
  dynamic_auto,
  dynamic_force_dynamic,
  dynamic_force_static,
  dynamic_revalidate,
  form_binding,
  hydrate_idle,
  hydrate_load,
  hydrate_manual,
  hydrate_media,
  hydrate_only,
  hydrate_visible,
  layout_module,
  loader_module,
  page_module,
  render_bundle_plan,
  render_form_manifest,
  render_page,
  render_page_manifest_entry,
  render_route_tree,
  render_router_manifest,
  render_server_action_manifest,
  server_action,
  server_component,
  with_action_name,
  with_assets,
  with_dynamic_mode,
  with_form,
  with_island,
  with_layout,
  with_loader,
  with_metadata,
}

///|
/// Re-exports scaffold generation helpers.
pub using @generator {
  type GeneratedArtifact,
  type ScaffoldField,
  type ScaffoldPlan,
  scaffold_field,
  scaffold_resource,
  scaffold_summary,
}

///|
/// Re-exports the high-level app runtime.
pub using @app {type MbtOnRailsApp, app, app_named, handle_request}

///|
pub using @demo_blog {demo_blog_app}

///|
/// View-layer contract helpers that complement the main facade.
pub using @view {
  type BoundaryKind,
  type ComponentContract,
  type PropContract,
  client_contract,
  prop_contract,
  render_component_manifest,
  server_contract,
  with_contract,
  with_fallback,
}
