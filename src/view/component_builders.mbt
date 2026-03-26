///|
/// Builds a server component reference.
#label_migration(name, allow_positional=true)
#label_migration(source_path, allow_positional=true)
#label_migration(props, allow_positional=true)
pub fn server_component(
  name~ : String,
  source_path~ : @support.MbtvPath,
  props~ : Array[(String, String)],
) -> VaporComponentRef {
  {
    name,
    source_path,
    props,
    hydration: None,
    is_server_component: true,
    contract: None,
    fallback_html: None,
    template_imports: [],
    children: [],
  }
}

///|
/// Builds a client island component reference.
#label_migration(name, allow_positional=true)
#label_migration(source_path, allow_positional=true)
#label_migration(props, allow_positional=true)
#label_migration(hydration, allow_positional=true)
pub fn client_component(
  name~ : String,
  source_path~ : @support.MbtvPath,
  props~ : Array[(String, String)],
  hydration~ : HydrationMode,
) -> VaporComponentRef {
  {
    name,
    source_path,
    props,
    hydration: Some(hydration),
    is_server_component: false,
    contract: None,
    fallback_html: None,
    template_imports: [],
    children: [],
  }
}

///|
/// Builds a layout module descriptor.
#label_migration(name, allow_positional=true)
#label_migration(file_path, allow_positional=true)
#label_migration(component, allow_positional=true)
pub fn layout_module(
  name~ : String,
  file_path~ : @support.MbtvPath,
  component~ : VaporComponentRef,
) -> LayoutModule {
  { name, file_path, component }
}

///|
/// Builds a loader module descriptor.
#label_migration(name, allow_positional=true)
#label_migration(cache_key, allow_positional=true)
#label_migration(revalidate_seconds, allow_positional=true)
#label_migration(depends_on, allow_positional=true)
pub fn loader_module(
  name~ : String,
  cache_key~ : String,
  revalidate_seconds~ : Int?,
  depends_on~ : Array[String],
) -> LoaderModule {
  { name, cache_key, revalidate_seconds, depends_on }
}

///|
/// Builds a form binding descriptor.
#label_migration(name, allow_positional=true)
#label_migration(action_name, allow_positional=true)
#label_migration(verb, allow_positional=true)
#label_migration(optimistic_key, allow_positional=true)
#label_migration(redirect_to, allow_positional=true)
pub fn form_binding(
  name~ : String,
  action_name~ : String,
  verb~ : String,
  optimistic_key~ : String?,
  redirect_to~ : String?,
) -> FormBinding {
  { name, action_name, verb, optimistic_key, redirect_to }
}

///|
/// Builds an asset manifest.
#label_migration(style_urls, allow_positional=true)
#label_migration(script_urls, allow_positional=true)
pub fn asset_manifest(
  style_urls~ : Array[String],
  script_urls~ : Array[String],
) -> AssetManifest {
  { style_urls, script_urls }
}

///|
/// Returns the default client bridge assets used by the demo runtime.
pub fn default_assets() -> AssetManifest {
  asset_manifest(style_urls=[], script_urls=["/assets/hydrate.js"])
}

///|
/// Builds a server action manifest entry.
#label_migration(name, allow_positional=true)
#label_migration(route, allow_positional=true)
#label_migration(input_fields, allow_positional=true)
#label_migration(output_type, allow_positional=true)
#label_migration(csrf_protected, allow_positional=true)
pub fn server_action(
  name~ : String,
  route~ : String,
  input_fields~ : Array[(String, String)],
  output_type~ : String,
  csrf_protected~ : Bool,
) -> ServerAction {
  { name, route, input_fields, output_type, csrf_protected }
}
