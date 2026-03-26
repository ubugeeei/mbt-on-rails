///|
/// Renders the client router manifest for all pages.
pub fn render_router_manifest(pages : Array[PageModule]) -> String {
  let entries : Array[String] = []
  for page in pages {
    entries.push(render_page_manifest_entry(page))
  }
  "[" + entries.join(", ") + "]"
}

///|
/// Renders a compact route tree for page-router style clients.
pub fn render_route_tree(pages : Array[PageModule]) -> String {
  let entries : Array[String] = []
  for page in pages {
    let segments : Array[String] = []
    for segment in @support.split_path(page.route_path) {
      segments.push(@support.json_string(segment))
    }
    entries.push(
      "{" +
      "\"route_name\": " +
      @support.json_string(page.route_name) +
      ", \"segments\": [" +
      segments.join(", ") +
      "]" +
      "}",
    )
  }
  "[" + entries.join(", ") + "]"
}

///|
/// Renders the component bundle plan needed by one page.
pub fn render_bundle_plan(page : PageModule) -> String {
  let sources : Array[String] = []
  collect_component_source(page.component, sources)
  for layout in page.layouts {
    collect_component_source(layout.component, sources)
    if not(sources.contains(layout.file_path.as_string())) {
      sources.push(layout.file_path.as_string())
    }
  }
  for island in page.client_islands {
    collect_component_source(island, sources)
  }
  let json_sources : Array[String] = []
  for source in sources {
    json_sources.push(@support.json_string(source))
  }
  "[" + json_sources.join(", ") + "]"
}

///|
/// Renders the component contract manifest consumed by the client bridge.
pub fn render_component_manifest(page : PageModule) -> String {
  let entries : Array[String] = []
  let seen : Array[String] = []
  collect_component_entries(page.component, entries, seen)
  for layout in page.layouts {
    collect_component_entries(layout.component, entries, seen)
  }
  for island in page.client_islands {
    collect_component_entries(island, entries, seen)
  }
  "[" + entries.join(", ") + "]"
}

///|
/// Renders the server action manifest consumed by the client bridge.
pub fn render_server_action_manifest(actions : Array[ServerAction]) -> String {
  let entries : Array[String] = []
  for action in actions {
    let inputs : Array[String] = []
    for field in action.input_fields {
      inputs.push(
        "{" +
        "\"name\": " +
        @support.json_string(field.0) +
        ", \"type\": " +
        @support.json_string(field.1) +
        "}",
      )
    }
    entries.push(
      "{" +
      "\"name\": " +
      @support.json_string(action.name) +
      ", \"route\": " +
      @support.json_string(action.route) +
      ", \"input_fields\": [" +
      inputs.join(", ") +
      "]" +
      ", \"output_type\": " +
      @support.json_string(action.output_type) +
      ", \"csrf_protected\": " +
      (if action.csrf_protected { "true" } else { "false" }) +
      "}",
    )
  }
  "[" + entries.join(", ") + "]"
}

///|
/// Renders the form binding manifest consumed by the client bridge.
pub fn render_form_manifest(forms : Array[FormBinding]) -> String {
  let entries : Array[String] = []
  for form in forms {
    let optimistic_key = match form.optimistic_key {
      Some(key) => @support.json_string(key)
      None => "null"
    }
    let redirect_to = match form.redirect_to {
      Some(path) => @support.json_string(path)
      None => "null"
    }
    entries.push(
      "{" +
      "\"name\": " +
      @support.json_string(form.name) +
      ", \"action_name\": " +
      @support.json_string(form.action_name) +
      ", \"method\": " +
      @support.json_string(form.verb) +
      ", \"optimistic_key\": " +
      optimistic_key +
      ", \"redirect_to\": " +
      redirect_to +
      "}",
    )
  }
  "[" + entries.join(", ") + "]"
}

///|
/// Renders the richer form builder manifest consumed by the client bridge.
pub fn render_form_builder_manifest(builders : Array[FormBuilder]) -> String {
  let entries : Array[String] = []
  for builder in builders {
    let optimistic_key = match builder.binding.optimistic_key {
      Some(key) => @support.json_string(key)
      None => "null"
    }
    let redirect_to = match builder.binding.redirect_to {
      Some(path) => @support.json_string(path)
      None => "null"
    }
    let description = match builder.description {
      Some(text) => @support.json_string(text)
      None => "null"
    }
    let fields : Array[String] = []
    for field in builder.fields {
      fields.push(
        "{" +
        "\"name\": " +
        @support.json_string(field.name) +
        ", \"kind\": " +
        @support.json_string(render_form_field_kind(field.field_kind)) +
        ", \"label\": " +
        @support.json_string(field.label) +
        ", \"required\": " +
        (if field.required { "true" } else { "false" }) +
        ", \"placeholder\": " +
        render_optional_json(field.placeholder) +
        ", \"value\": " +
        render_optional_json(field.value) +
        ", \"autocomplete\": " +
        render_optional_json(field.autocomplete) +
        ", \"help_text\": " +
        render_optional_json(field.help_text) +
        "}",
      )
    }
    entries.push(
      "{" +
      "\"name\": " +
      @support.json_string(builder.name) +
      ", \"binding_name\": " +
      @support.json_string(builder.binding.name) +
      ", \"action_name\": " +
      @support.json_string(builder.binding.action_name) +
      ", \"method\": " +
      @support.json_string(builder.binding.verb) +
      ", \"optimistic_key\": " +
      optimistic_key +
      ", \"redirect_to\": " +
      redirect_to +
      ", \"submit_label\": " +
      @support.json_string(builder.submit_label) +
      ", \"description\": " +
      description +
      ", \"fields\": [" +
      fields.join(", ") +
      "]" +
      "}",
    )
  }
  "[" + entries.join(", ") + "]"
}

///|
/// Renders one component entry for the component contract manifest.
fn render_component_entry(component : VaporComponentRef) -> String {
  let boundary = match component.contract {
    Some(contract) => render_boundary_kind(contract.boundary)
    None => if component.is_server_component { "server" } else { "client" }
  }
  let scope_id = @support.json_string(make_scope_id(component.name))
  let client_path = @support.json_string(client_module_path(component.name))
  let transport = match component.contract {
    Some(contract) => @support.json_string(contract.transport)
    None => "null"
  }
  let async_only = match component.contract {
    Some(contract) => if contract.async_only { "true" } else { "false" }
    None => "false"
  }
  let props = match component.contract {
    Some(contract) => render_prop_contracts(contract.props)
    None => "[]"
  }
  let props_binding = match component.contract {
    Some(contract) => render_optional_json(contract.props_binding)
    None => "null"
  }
  let emits_binding = match component.contract {
    Some(contract) => render_optional_json(contract.emits_binding)
    None => "null"
  }
  let slots_binding = match component.contract {
    Some(contract) => render_optional_json(contract.slots_binding)
    None => "null"
  }
  let emits = match component.contract {
    Some(contract) => render_emit_contracts(contract.emits)
    None => "[]"
  }
  let slots = match component.contract {
    Some(contract) => render_slot_contracts(contract.slots)
    None => "[]"
  }
  let template_refs = match component.contract {
    Some(contract) => render_template_ref_contracts(contract.template_refs)
    None => "[]"
  }
  let fallback_html = match component.fallback_html {
    Some(html) => @support.json_string(html)
    None => "null"
  }
  let template_imports = render_template_imports(component.template_imports)
  let children = render_vapor_nodes(component.children)
  "{" +
  "\"name\": " +
  @support.json_string(component.name) +
  ", \"source_path\": " +
  @support.json_string(component.source_path.as_string()) +
  ", \"scope_id\": " +
  scope_id +
  ", \"client_module_path\": " +
  client_path +
  ", \"boundary\": " +
  @support.json_string(boundary) +
  ", \"transport\": " +
  transport +
  ", \"async_only\": " +
  async_only +
  ", \"props\": " +
  props +
  ", \"props_binding\": " +
  props_binding +
  ", \"emits_binding\": " +
  emits_binding +
  ", \"slots_binding\": " +
  slots_binding +
  ", \"emits\": " +
  emits +
  ", \"slots\": " +
  slots +
  ", \"template_refs\": " +
  template_refs +
  ", \"fallback_html\": " +
  fallback_html +
  ", \"template_imports\": " +
  template_imports +
  ", \"children\": " +
  children +
  "}"
}

///|
fn render_optional_json(value : String?) -> String {
  match value {
    Some(text) => @support.json_string(text)
    None => "null"
  }
}

///|
fn render_form_field_kind(kind : FormFieldKind) -> String {
  match kind {
    TextInput => "text"
    EmailInput => "email"
    PasswordInput => "password"
    TextArea => "textarea"
    HiddenInput => "hidden"
    CheckboxInput => "checkbox"
  }
}

///|
/// Renders a prop contract list into JSON.
fn render_prop_contracts(props : Array[PropContract]) -> String {
  let entries : Array[String] = []
  for prop in props {
    entries.push(
      "{" +
      "\"name\": " +
      @support.json_string(prop.name) +
      ", \"type\": " +
      @support.json_string(prop.type_name) +
      ", \"required\": " +
      (if prop.required { "true" } else { "false" }) +
      ", \"description\": " +
      @support.json_string(prop.description) +
      ", \"default_value\": " +
      render_optional_json(prop.default_value) +
      "}",
    )
  }
  "[" + entries.join(", ") + "]"
}

///|
fn render_emit_contracts(emits : Array[EmitContract]) -> String {
  let entries : Array[String] = []
  for emit in emits {
    entries.push(
      "{" +
      "\"name\": " +
      @support.json_string(emit.name) +
      ", \"signature\": " +
      @support.json_string(emit.signature) +
      ", \"description\": " +
      render_optional_json(emit.description) +
      "}",
    )
  }
  "[" + entries.join(", ") + "]"
}

///|
fn render_slot_contracts(slots : Array[SlotContract]) -> String {
  let entries : Array[String] = []
  for slot in slots {
    entries.push(
      "{" +
      "\"name\": " +
      @support.json_string(slot.name) +
      ", \"signature\": " +
      @support.json_string(slot.signature) +
      ", \"required\": " +
      (if slot.required { "true" } else { "false" }) +
      ", \"description\": " +
      render_optional_json(slot.description) +
      "}",
    )
  }
  "[" + entries.join(", ") + "]"
}

///|
fn render_template_ref_contracts(refs : Array[TemplateRefContract]) -> String {
  let entries : Array[String] = []
  for template_ref in refs {
    entries.push(
      "{" +
      "\"ref_name\": " +
      @support.json_string(template_ref.ref_name) +
      ", \"binding_name\": " +
      render_optional_json(template_ref.binding_name) +
      "}",
    )
  }
  "[" + entries.join(", ") + "]"
}

///|
/// Renders one boundary kind into a manifest-friendly string.
fn render_boundary_kind(kind : BoundaryKind) -> String {
  match kind {
    ServerBoundary => "server"
    ClientBoundary => "client"
  }
}

///|
fn collect_component_source(
  component : VaporComponentRef,
  sources : Array[String],
) -> Unit {
  let source = component.source_path.as_string()
  if not(sources.contains(source)) {
    sources.push(source)
  }
  for imported in component.template_imports {
    collect_component_source(imported.component, sources)
  }
}

///|
fn collect_component_entries(
  component : VaporComponentRef,
  entries : Array[String],
  seen : Array[String],
) -> Unit {
  let key = component.name + "::" + component.source_path.as_string()
  if seen.contains(key) {
    return
  }
  seen.push(key)
  entries.push(render_component_entry(component))
  for imported in component.template_imports {
    collect_component_entries(imported.component, entries, seen)
  }
}

///|
fn render_template_imports(imports : Array[TemplateImport]) -> String {
  let entries : Array[String] = []
  for imported in imports {
    entries.push(
      "{" +
      "\"local_name\": " +
      @support.json_string(imported.local_name) +
      ", \"component_name\": " +
      @support.json_string(imported.component.name) +
      ", \"source_path\": " +
      @support.json_string(imported.component.source_path.as_string()) +
      ", \"boundary\": " +
      @support.json_string(render_component_boundary(imported.component)) +
      "}",
    )
  }
  "[" + entries.join(", ") + "]"
}

///|
fn render_vapor_nodes(nodes : Array[VaporNode]) -> String {
  let entries : Array[String] = []
  for node in nodes {
    entries.push(render_manifest_vapor_node(node))
  }
  "[" + entries.join(", ") + "]"
}

///|
fn render_manifest_vapor_node(node : VaporNode) -> String {
  match node {
    Mounted(mounted) =>
      "{" +
      "\"kind\": \"component\"" +
      ", \"import_name\": " +
      @support.json_string(mounted.import_name) +
      ", \"props\": " +
      @support.entries_to_json(mounted.props) +
      "}"
    Suspense(boundary) =>
      "{" +
      "\"kind\": \"suspense\"" +
      ", \"name\": " +
      @support.json_string(boundary.name) +
      ", \"fallback_html\": " +
      @support.json_string(boundary.fallback_html) +
      ", \"children\": " +
      render_vapor_nodes(boundary.children) +
      "}"
  }
}

///|
fn render_component_boundary(component : VaporComponentRef) -> String {
  match component.contract {
    Some(contract) => render_boundary_kind(contract.boundary)
    None => if component.is_server_component { "server" } else { "client" }
  }
}
