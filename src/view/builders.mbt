///|
/// Builds a server component reference.
pub fn server_component(
  name : String,
  source_path : String,
  props : Array[(String, String)],
) -> VaporComponentRef {
  { name, source_path, props, hydration: None, is_server_component: true }
}

///|
/// Builds a client island component reference.
pub fn client_component(
  name : String,
  source_path : String,
  props : Array[(String, String)],
  hydration : HydrationMode,
) -> VaporComponentRef {
  {
    name,
    source_path,
    props,
    hydration: Some(hydration),
    is_server_component: false,
  }
}

///|
/// Builds a layout module descriptor.
pub fn layout_module(
  name : String,
  file_path : String,
  component : VaporComponentRef,
) -> LayoutModule {
  { name, file_path, component }
}

///|
/// Builds a loader module descriptor.
pub fn loader_module(
  name : String,
  cache_key : String,
  revalidate_seconds : Int?,
  depends_on : Array[String],
) -> LoaderModule {
  { name, cache_key, revalidate_seconds, depends_on }
}

///|
/// Builds a form binding descriptor.
pub fn form_binding(
  name : String,
  action_name : String,
  verb : String,
  optimistic_key : String?,
  redirect_to : String?,
) -> FormBinding {
  { name, action_name, verb, optimistic_key, redirect_to }
}

///|
/// Builds an asset manifest.
pub fn asset_manifest(
  style_urls : Array[String],
  script_urls : Array[String],
) -> AssetManifest {
  { style_urls, script_urls }
}

///|
/// Returns the default client bridge assets used by the demo runtime.
pub fn default_assets() -> AssetManifest {
  asset_manifest([], ["/assets/hydrate.js"])
}

///|
/// Builds a server action manifest entry.
pub fn server_action(
  name : String,
  route : String,
  input_fields : Array[(String, String)],
  output_type : String,
  csrf_protected : Bool,
) -> ServerAction {
  { name, route, input_fields, output_type, csrf_protected }
}

///|
/// Builds a page module with empty optional metadata.
pub fn page_module(
  route_name : String,
  route_path : String,
  file_path : String,
  title : String,
  component : VaporComponentRef,
) -> PageModule {
  {
    route_name,
    route_path,
    file_path,
    title,
    component,
    layouts: [],
    loader: None,
    action_name: None,
    client_islands: [],
    forms: [],
    metadata: [],
    dynamic_mode: Auto,
    assets: default_assets(),
  }
}

///|
/// Returns a page with one more layout applied.
pub fn with_layout(page : PageModule, layout : LayoutModule) -> PageModule {
  let layouts = @support.clone_array(page.layouts)
  layouts.push(layout)
  { ..page, layouts, }
}

///|
/// Returns a page with a loader attached.
pub fn with_loader(page : PageModule, loader : LoaderModule) -> PageModule {
  { ..page, loader: Some(loader) }
}

///|
/// Returns a page with a default action name attached.
pub fn with_action_name(page : PageModule, action_name : String) -> PageModule {
  { ..page, action_name: Some(action_name) }
}

///|
/// Returns a page with one more client island.
pub fn with_island(page : PageModule, island : VaporComponentRef) -> PageModule {
  let client_islands = @support.clone_array(page.client_islands)
  client_islands.push(island)
  { ..page, client_islands, }
}

///|
/// Returns a page with one more form binding.
pub fn with_form(page : PageModule, form : FormBinding) -> PageModule {
  let forms = @support.clone_array(page.forms)
  forms.push(form)
  { ..page, forms, }
}

///|
/// Returns a page with an extra metadata entry.
pub fn with_metadata(
  page : PageModule,
  key : String,
  value : String,
) -> PageModule {
  let metadata = @support.clone_array(page.metadata)
  metadata.push((key, value))
  { ..page, metadata, }
}

///|
/// Returns a page with a different dynamic rendering mode.
pub fn with_dynamic_mode(
  page : PageModule,
  dynamic_mode : DynamicMode,
) -> PageModule {
  { ..page, dynamic_mode, }
}

///|
/// Returns a page with a different asset manifest.
pub fn with_assets(page : PageModule, assets : AssetManifest) -> PageModule {
  { ..page, assets, }
}

///|
/// Returns the manual hydration mode.
pub fn hydrate_manual() -> HydrationMode {
  Manual
}

///|
/// Returns the eager-on-load hydration mode.
pub fn hydrate_load() -> HydrationMode {
  Load
}

///|
/// Returns the idle-time hydration mode.
pub fn hydrate_idle() -> HydrationMode {
  Idle
}

///|
/// Returns the viewport-visible hydration mode.
pub fn hydrate_visible() -> HydrationMode {
  Visible
}

///|
/// Returns a media-query hydration mode.
pub fn hydrate_media(query : String) -> HydrationMode {
  Media(query)
}

///|
/// Returns the client-only hydration mode.
pub fn hydrate_only() -> HydrationMode {
  Only
}

///|
/// Returns the server-deferred hydration mode.
pub fn defer_on_server() -> HydrationMode {
  ServerDefer
}

///|
/// Returns the default dynamic page mode.
pub fn dynamic_auto() -> DynamicMode {
  Auto
}

///|
/// Returns the force-dynamic page mode.
pub fn dynamic_force_dynamic() -> DynamicMode {
  ForceDynamic
}

///|
/// Returns the force-static page mode.
pub fn dynamic_force_static() -> DynamicMode {
  ForceStatic
}

///|
/// Returns a revalidation-based page mode.
pub fn dynamic_revalidate(seconds : Int) -> DynamicMode {
  Revalidate(seconds)
}
