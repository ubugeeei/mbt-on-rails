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
  let sources : Array[String] = [page.component.source_path.as_string()]
  for layout in page.layouts {
    sources.push(layout.file_path.as_string())
  }
  for island in page.client_islands {
    sources.push(island.source_path.as_string())
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
  let entries : Array[String] = [render_component_entry(page.component)]
  for layout in page.layouts {
    entries.push(render_component_entry(layout.component))
  }
  for island in page.client_islands {
    entries.push(render_component_entry(island))
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
/// Renders one component entry for the component contract manifest.
fn render_component_entry(component : VaporComponentRef) -> String {
  let boundary = match component.contract {
    Some(contract) => render_boundary_kind(contract.boundary)
    None => if component.is_server_component { "server" } else { "client" }
  }
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
  let fallback_html = match component.fallback_html {
    Some(html) => @support.json_string(html)
    None => "null"
  }
  "{" +
  "\"name\": " +
  @support.json_string(component.name) +
  ", \"source_path\": " +
  @support.json_string(component.source_path.as_string()) +
  ", \"boundary\": " +
  @support.json_string(boundary) +
  ", \"transport\": " +
  transport +
  ", \"async_only\": " +
  async_only +
  ", \"props\": " +
  props +
  ", \"fallback_html\": " +
  fallback_html +
  "}"
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
