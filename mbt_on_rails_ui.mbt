///|
/// View-layer contract helpers that complement the main facade.

///|
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
