///|
/// Builds one prop contract entry for a server or client component.
#label_migration(name, allow_positional=true)
#label_migration(type_name, allow_positional=true)
#label_migration(required, allow_positional=true)
#label_migration(description, allow_positional=true)
pub fn prop_contract(
  name~ : String,
  type_name~ : String,
  required~ : Bool,
  description~ : String,
) -> PropContract {
  { name, type_name, required, description }
}

///|
/// Builds a server-side component contract.
#label_migration(props, allow_positional=true)
#label_migration(async_only, allow_positional=true)
pub fn server_contract(
  props~ : Array[PropContract],
  async_only~ : Bool,
) -> ComponentContract {
  { boundary: ServerBoundary, props, transport: "json", async_only }
}

///|
/// Builds a client-side component contract.
pub fn client_contract(props : Array[PropContract]) -> ComponentContract {
  { boundary: ClientBoundary, props, transport: "json", async_only: false }
}

///|
/// Attaches a client/server contract to a component reference.
pub fn with_contract(
  component : VaporComponentRef,
  contract : ComponentContract,
) -> VaporComponentRef {
  { ..component, contract: Some(contract) }
}

///|
/// Attaches trusted SSR fallback HTML to a component placeholder.
pub fn with_fallback(
  component : VaporComponentRef,
  fallback_html : String,
) -> VaporComponentRef {
  { ..component, fallback_html: Some(fallback_html) }
}
