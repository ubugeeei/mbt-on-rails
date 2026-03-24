///|
/// Builds a server component reference.
pub fn server_component(
  name : String,
  source_path : String,
  props : Array[(String, String)],
) -> VaporComponentRef {
  {
    name,
    source_path,
    props,
    hydration: None,
    is_server_component: true,
    contract: None,
    fallback_html: None,
  }
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
    contract: None,
    fallback_html: None,
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
