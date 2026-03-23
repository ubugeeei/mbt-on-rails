///|
/// Lists the hydration strategies supported for client islands.
pub enum HydrationMode {
  Manual
  Load
  Idle
  Visible
  Media(String)
  Only
  ServerDefer
} derive(Eq, Show)

///|
/// Lists the cache and rendering modes supported for a page.
pub enum DynamicMode {
  Auto
  ForceDynamic
  ForceStatic
  Revalidate(Int)
} derive(Eq, Show)

///|
/// References a Vapor-style component module and its props.
pub struct VaporComponentRef {
  name : String
  source_path : String
  props : Array[(String, String)]
  hydration : HydrationMode?
  is_server_component : Bool
}

///|
/// Describes a server action exposed to the client runtime.
pub struct ServerAction {
  name : String
  route : String
  input_fields : Array[(String, String)]
  output_type : String
  csrf_protected : Bool
}

///|
/// Describes a loader module for route-level data fetching.
pub struct LoaderModule {
  name : String
  cache_key : String
  revalidate_seconds : Int?
  depends_on : Array[String]
}

///|
/// Describes a shared layout used by one or more pages.
pub struct LayoutModule {
  name : String
  file_path : String
  component : VaporComponentRef
}

///|
/// Binds a form on the page to a server action.
pub struct FormBinding {
  name : String
  action_name : String
  verb : String
  optimistic_key : String?
  redirect_to : String?
}

///|
/// Lists the styles and scripts emitted for a rendered page.
pub struct AssetManifest {
  style_urls : Array[String]
  script_urls : Array[String]
}

///|
/// Describes a page module and its SSR/runtime metadata.
pub struct PageModule {
  route_name : String
  route_path : String
  file_path : String
  title : String
  component : VaporComponentRef
  layouts : Array[LayoutModule]
  loader : LoaderModule?
  action_name : String?
  client_islands : Array[VaporComponentRef]
  forms : Array[FormBinding]
  metadata : Array[(String, String)]
  dynamic_mode : DynamicMode
  assets : AssetManifest
}

///|
/// Holds the HTML and manifest fragments produced by SSR.
pub struct RenderedPage {
  html : String
  data_json : String
  router_manifest_entry : String
}
