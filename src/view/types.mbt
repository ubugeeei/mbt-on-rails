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
/// Stores one typed template ref handle in a Vapor Moon-compatible shape.
pub struct TemplateRef[T] {
  name : String
  phantom : T?
}

///|
/// Distinguishes server-rendered components from client islands.
pub enum BoundaryKind {
  ServerBoundary
  ClientBoundary
} derive(Eq, Show)

///|
/// Declares one JSON-serializable prop accepted by a component.
pub struct PropContract {
  name : String
  type_name : String
  required : Bool
  description : String
  default_value : String?
}

///|
/// Declares one typed emit callback exposed by a component.
pub struct EmitContract {
  name : String
  signature : String
  description : String?
}

///|
/// Declares one typed slot accepted by a component.
pub struct SlotContract {
  name : String
  signature : String
  required : Bool
  description : String?
}

///|
/// Declares one template ref surfaced from the compiled component.
pub struct TemplateRefContract {
  ref_name : String
  binding_name : String?
}

///|
/// Captures the client/server contract attached to a component.
pub struct ComponentContract {
  boundary : BoundaryKind
  props : Array[PropContract]
  props_binding : String?
  emits_binding : String?
  slots_binding : String?
  emits : Array[EmitContract]
  slots : Array[SlotContract]
  template_refs : Array[TemplateRefContract]
  transport : String
  async_only : Bool
}

///|
/// Declares one explicit component import available to a template.
pub struct TemplateImport {
  local_name : String
  component : VaporComponentRef
}

///|
/// Mounts one imported component inside a server-rendered component tree.
pub struct MountedComponent {
  import_name : String
  props : Array[(String, String)]
}

///|
/// Describes one suspense-like boundary for deferred server rendering.
pub struct SuspenseBoundary {
  name : String
  fallback_html : String
  children : Array[VaporNode]
}

///|
/// Represents one nested node in a server-rendered component tree.
pub enum VaporNode {
  Mounted(MountedComponent)
  Suspense(SuspenseBoundary)
}

///|
/// References a Vapor-style component module and its props.
pub struct VaporComponentRef {
  name : String
  source_path : @support.MbtvPath
  props : Array[(String, String)]
  hydration : HydrationMode?
  is_server_component : Bool
  contract : ComponentContract?
  fallback_html : String?
  template_imports : Array[TemplateImport]
  children : Array[VaporNode]
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
  file_path : @support.MbtvPath
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
/// Lists the field controls a generated form builder can emit.
pub enum FormFieldKind {
  TextInput
  EmailInput
  PasswordInput
  TextArea
  HiddenInput
  CheckboxInput
} derive(Eq, Show)

///|
/// Describes one typed field used by a form builder.
pub struct FormField {
  name : String
  field_kind : FormFieldKind
  label : String
  required : Bool
  placeholder : String?
  value : String?
  autocomplete : String?
  help_text : String?
}

///|
/// Describes one Rails-style form builder attached to a page.
pub struct FormBuilder {
  name : String
  binding : FormBinding
  fields : Array[FormField]
  submit_label : String
  description : String?
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
  file_path : @support.MbtvPath
  title : String
  component : VaporComponentRef
  layouts : Array[LayoutModule]
  loader : LoaderModule?
  action_name : String?
  client_islands : Array[VaporComponentRef]
  forms : Array[FormBinding]
  form_builders : Array[FormBuilder]
  metadata : Array[(String, String)]
  dynamic_mode : DynamicMode
  assets : AssetManifest
}

///|
/// Holds the HTML and manifest fragments produced by SSR.
pub struct RenderedPage {
  html : String
  data_json : String
  component_manifest_json : String
  form_builder_manifest_json : String
  router_manifest_entry : String
}
