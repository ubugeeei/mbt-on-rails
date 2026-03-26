///|
/// Builds a page module with empty optional metadata.
#label_migration(route_name, allow_positional=true)
#label_migration(route_path, allow_positional=true)
#label_migration(file_path, allow_positional=true)
#label_migration(title, allow_positional=true)
#label_migration(component, allow_positional=true)
pub fn page_module(
  route_name~ : String,
  route_path~ : String,
  file_path~ : @support.MbtvPath,
  title~ : String,
  component~ : VaporComponentRef,
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
