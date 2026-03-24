///|
/// Builds one prop contract entry for a server or client component.
pub fn prop_contract(
  name : String,
  type_name : String,
  required : Bool,
  description : String,
) -> PropContract {
  { name, type_name, required, description }
}

///|
/// Builds a server-side component contract.
pub fn server_contract(
  props : Array[PropContract],
  async_only : Bool,
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
