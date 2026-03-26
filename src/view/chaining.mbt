///|
/// Chainable alias for `with_contract`.
pub fn VaporComponentRef::with_contract(
  self : VaporComponentRef,
  contract : ComponentContract,
) -> VaporComponentRef {
  { ..self, contract: Some(contract) }
}

///|
/// Chainable alias for `with_fallback`.
pub fn VaporComponentRef::with_fallback(
  self : VaporComponentRef,
  fallback_html : String,
) -> VaporComponentRef {
  { ..self, fallback_html: Some(fallback_html) }
}

///|
/// Chainable alias for `with_layout`.
pub fn PageModule::with_layout(
  self : PageModule,
  layout : LayoutModule,
) -> PageModule {
  let layouts = @support.clone_array(self.layouts)
  layouts.push(layout)
  { ..self, layouts, }
}

///|
/// Chainable alias for `with_loader`.
pub fn PageModule::with_loader(
  self : PageModule,
  loader : LoaderModule,
) -> PageModule {
  { ..self, loader: Some(loader) }
}

///|
/// Chainable alias for `with_action_name`.
pub fn PageModule::with_action_name(
  self : PageModule,
  action_name : String,
) -> PageModule {
  { ..self, action_name: Some(action_name) }
}

///|
/// Chainable alias for `with_island`.
pub fn PageModule::with_island(
  self : PageModule,
  island : VaporComponentRef,
) -> PageModule {
  let client_islands = @support.clone_array(self.client_islands)
  client_islands.push(island)
  { ..self, client_islands, }
}

///|
/// Chainable alias for `with_form`.
pub fn PageModule::with_form(
  self : PageModule,
  form : FormBinding,
) -> PageModule {
  let forms = @support.clone_array(self.forms)
  forms.push(form)
  { ..self, forms, }
}

///|
/// Chainable alias for `with_metadata`.
pub fn PageModule::with_metadata(
  self : PageModule,
  key : String,
  value : String,
) -> PageModule {
  let metadata = @support.clone_array(self.metadata)
  metadata.push((key, value))
  { ..self, metadata, }
}

///|
/// Chainable alias for `with_dynamic_mode`.
pub fn PageModule::with_dynamic_mode(
  self : PageModule,
  dynamic_mode : DynamicMode,
) -> PageModule {
  { ..self, dynamic_mode, }
}

///|
/// Chainable alias for `with_assets`.
pub fn PageModule::with_assets(
  self : PageModule,
  assets : AssetManifest,
) -> PageModule {
  { ..self, assets, }
}
