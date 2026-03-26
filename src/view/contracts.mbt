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
  default_value? : String? = None,
) -> PropContract {
  { name, type_name, required, description, default_value }
}

///|
/// Builds one emit contract entry for a server or client component.
#label_migration(name, allow_positional=true)
#label_migration(signature, allow_positional=true)
pub fn emit_contract(
  name~ : String,
  signature~ : String,
  description? : String? = None,
) -> EmitContract {
  { name, signature, description }
}

///|
/// Builds one slot contract entry for a server or client component.
#label_migration(name, allow_positional=true)
#label_migration(signature, allow_positional=true)
pub fn slot_contract(
  name~ : String,
  signature~ : String,
  required? : Bool = false,
  description? : String? = None,
) -> SlotContract {
  { name, signature, required, description }
}

///|
/// Builds one template ref contract entry for a compiled component.
#label_migration(ref_name, allow_positional=true)
pub fn template_ref_contract(
  ref_name~ : String,
  binding_name? : String? = None,
) -> TemplateRefContract {
  { ref_name, binding_name }
}

///|
/// Builds a server-side component contract.
#label_migration(props, allow_positional=true)
#label_migration(async_only, allow_positional=true)
pub fn server_contract(
  props~ : Array[PropContract],
  async_only~ : Bool,
  props_binding? : String? = None,
  emits_binding? : String? = None,
  slots_binding? : String? = None,
  emits? : Array[EmitContract] = [],
  slots? : Array[SlotContract] = [],
  template_refs? : Array[TemplateRefContract] = [],
  transport? : String = "json",
) -> ComponentContract {
  {
    boundary: ServerBoundary,
    props: @support.clone_array(props),
    props_binding,
    emits_binding,
    slots_binding,
    emits: @support.clone_array(emits),
    slots: @support.clone_array(slots),
    template_refs: @support.clone_array(template_refs),
    transport,
    async_only,
  }
}

///|
/// Builds a client-side component contract.
#label_migration(props, allow_positional=true)
pub fn client_contract(
  props~ : Array[PropContract],
  props_binding? : String? = None,
  emits_binding? : String? = None,
  slots_binding? : String? = None,
  emits? : Array[EmitContract] = [],
  slots? : Array[SlotContract] = [],
  template_refs? : Array[TemplateRefContract] = [],
  transport? : String = "json",
) -> ComponentContract {
  {
    boundary: ClientBoundary,
    props: @support.clone_array(props),
    props_binding,
    emits_binding,
    slots_binding,
    emits: @support.clone_array(emits),
    slots: @support.clone_array(slots),
    template_refs: @support.clone_array(template_refs),
    transport,
    async_only: false,
  }
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
