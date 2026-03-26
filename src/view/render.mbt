///|
/// Renders a page into SSR HTML plus runtime metadata payloads.
pub fn render_page(
  page : PageModule,
  route_params : Array[(String, String)],
  loader_data : Array[(String, String)],
  actions : Array[ServerAction],
) -> RenderedPage {
  let payload = @support.append_entries(route_params, loader_data)
  let page_payload = @support.clone_array(payload)
  page_payload.push(("route_name", page.route_name))
  page_payload.push(("route_path", page.route_path))
  page_payload.push(("dynamic_mode", render_dynamic_mode(page.dynamic_mode)))
  match page.loader {
    Some(loader) => page_payload.push(("loader", loader.name))
    None => ()
  }
  let data_json = @support.entries_to_json(page_payload)
  let component_manifest_json = render_component_manifest(page)

  let body = StringBuilder::new()
  body.write_string(
    "<main id=\"mbor-root\" data-mbor-page=\"" +
    @support.escape_html(page.route_name) +
    "\" data-mbor-dynamic=\"" +
    @support.escape_html(render_dynamic_mode(page.dynamic_mode)) +
    "\">",
  )
  for layout in page.layouts {
    body.write_string(render_layout_placeholder(layout))
  }
  body.write_string(render_component_placeholder(page.component))
  for island in page.client_islands {
    body.write_string(render_component_placeholder(island))
  }
  body.write_string("</main>")

  let head_bits : Array[String] = [
    "<meta charset=\"utf-8\">",
    "<title>" + @support.escape_html(page.title) + "</title>",
    "<meta name=\"mbor-route\" content=\"" +
    @support.escape_html(page.route_path) +
    "\">",
    "<meta name=\"mbor-dynamic\" content=\"" +
    @support.escape_html(render_dynamic_mode(page.dynamic_mode)) +
    "\">",
  ]
  for entry in page.metadata {
    head_bits.push(
      "<meta name=\"" +
      @support.escape_html(entry.0) +
      "\" content=\"" +
      @support.escape_html(entry.1) +
      "\">",
    )
  }
  for style_url in page.assets.style_urls {
    head_bits.push(
      "<link rel=\"stylesheet\" href=\"" +
      @support.escape_html(style_url) +
      "\">",
    )
  }

  let script_bits : Array[String] = []
  script_bits.push(
    "<script type=\"application/json\" id=\"mbor-data\">" +
    @support.escape_html(data_json) +
    "</script>",
  )
  script_bits.push(
    "<script type=\"application/json\" id=\"mbor-actions\">" +
    @support.escape_html(render_server_action_manifest(actions)) +
    "</script>",
  )
  script_bits.push(
    "<script type=\"application/json\" id=\"mbor-components\">" +
    @support.escape_html(component_manifest_json) +
    "</script>",
  )
  script_bits.push(
    "<script type=\"application/json\" id=\"mbor-forms\">" +
    @support.escape_html(render_form_manifest(page.forms)) +
    "</script>",
  )
  for script_url in page.assets.script_urls {
    script_bits.push(
      "<script src=\"" + @support.escape_html(script_url) + "\" defer></script>",
    )
  }

  let html = "<!doctype html><html><head>" +
    head_bits.join("") +
    "</head><body>" +
    body.to_string() +
    script_bits.join("") +
    "</body></html>"

  {
    html,
    data_json,
    component_manifest_json,
    router_manifest_entry: render_page_manifest_entry(page),
  }
}

///|
/// Renders one page entry in the client router manifest.
pub fn render_page_manifest_entry(page : PageModule) -> String {
  let loader = match page.loader {
    Some(current) => @support.json_string(current.name)
    None => "null"
  }
  let action = match page.action_name {
    Some(name) => @support.json_string(name)
    None => "null"
  }
  let layout_names : Array[String] = []
  for layout in page.layouts {
    layout_names.push(@support.json_string(layout.name))
  }
  "{" +
  "\"route_name\": " +
  @support.json_string(page.route_name) +
  ", \"route_path\": " +
  @support.json_string(page.route_path) +
  ", \"file_path\": " +
  @support.json_string(page.file_path.as_string()) +
  ", \"loader\": " +
  loader +
  ", \"action\": " +
  action +
  ", \"dynamic_mode\": " +
  @support.json_string(render_dynamic_mode(page.dynamic_mode)) +
  ", \"layouts\": [" +
  layout_names.join(", ") +
  "]" +
  "}"
}

///|
/// Renders one layout placeholder tag.
fn render_layout_placeholder(layout : LayoutModule) -> String {
  "<div class=\"mbor-layout\" data-mbor-layout=\"" +
  @support.escape_html(layout.name) +
  "\" data-mbor-layout-source=\"" +
  @support.escape_html(layout.file_path.as_string()) +
  "\"></div>"
}

///|
/// Renders one component placeholder tag.
fn render_component_placeholder(component : VaporComponentRef) -> String {
  render_component_placeholder_with_import(component, None)
}

///|
fn render_component_placeholder_with_import(
  component : VaporComponentRef,
  import_name : String?,
) -> String {
  let props_json = @support.entries_to_json(component.props)
  let attrs = StringBuilder::new()
  let boundary = match component.contract {
    Some(contract) => render_boundary_attr(contract.boundary)
    None => if component.is_server_component { "server" } else { "client" }
  }
  attrs.write_string(
    "data-mbor-component=\"" + @support.escape_html(component.name) + "\" ",
  )
  attrs.write_string(
    "data-mbor-source=\"" +
    @support.escape_html(component.source_path.as_string()) +
    "\" ",
  )
  attrs.write_string(
    "data-mbor-props='" + @support.escape_html(props_json) + "' ",
  )
  attrs.write_string(
    "data-mbor-boundary=\"" + @support.escape_html(boundary) + "\" ",
  )
  match import_name {
    Some(name) =>
      attrs.write_string(
        "data-mbor-import=\"" + @support.escape_html(name) + "\" ",
      )
    None => ()
  }
  if not(component.template_imports.is_empty()) {
    attrs.write_string(
      "data-mbor-template-imports='" +
      @support.escape_html(
        render_template_import_names(component.template_imports),
      ) +
      "' ",
    )
  }
  if component.is_server_component {
    attrs.write_string("data-mbor-server-component=\"true\" ")
  } else {
    attrs.write_string("data-mbor-island=\"true\" ")
    match component.hydration {
      Some(mode) =>
        attrs.write_string(
          "data-mbor-hydration=\"" +
          @support.escape_html(render_hydration_mode(mode)) +
          "\" ",
        )
      None => ()
    }
  }
  match component.contract {
    Some(contract) =>
      attrs.write_string(
        "data-mbor-transport=\"" +
        @support.escape_html(contract.transport) +
        "\" ",
      )
    None => ()
  }
  let fallback = match component.fallback_html {
    Some(html) => "<template data-mbor-fallback>" + html + "</template>"
    None => ""
  }
  let nested = render_component_children(component)
  "<section class=\"mbor-component\" " +
  attrs.to_string().trim().to_string() +
  ">" +
  fallback +
  nested +
  "</section>"
}

///|
fn render_component_children(component : VaporComponentRef) -> String {
  let parts : Array[String] = []
  for child in component.children {
    parts.push(render_tree_node(component, child))
  }
  parts.join("")
}

///|
fn render_tree_node(parent : VaporComponentRef, node : VaporNode) -> String {
  match node {
    Mounted(mounted) =>
      match render_resolve_template_import(parent, mounted.import_name) {
        Some(imported) => {
          let child = {
            ..imported.component,
            props: render_merge_props(imported.component.props, mounted.props),
          }
          render_component_placeholder_with_import(
            child,
            Some(imported.local_name),
          )
        }
        None =>
          "<div class=\"mbor-error\" data-mbor-missing-import=\"" +
          @support.escape_html(mounted.import_name) +
          "\"></div>"
      }
    Suspense(boundary) => {
      let children : Array[String] = []
      for nested in boundary.children {
        children.push(render_tree_node(parent, nested))
      }
      "<div class=\"mbor-suspense\" data-mbor-suspense=\"" +
      @support.escape_html(boundary.name) +
      "\"><template data-mbor-suspense-fallback>" +
      boundary.fallback_html +
      "</template>" +
      children.join("") +
      "</div>"
    }
  }
}

///|
/// Renders one hydration mode into a runtime attribute value.
fn render_hydration_mode(mode : HydrationMode) -> String {
  match mode {
    Manual => "manual"
    Load => "client:load"
    Idle => "client:idle"
    Visible => "client:visible"
    Media(query) => "client:media=" + query
    Only => "client:only"
    ServerDefer => "server:defer"
  }
}

///|
/// Renders one dynamic mode into a manifest value.
fn render_dynamic_mode(mode : DynamicMode) -> String {
  match mode {
    Auto => "auto"
    ForceDynamic => "force-dynamic"
    ForceStatic => "force-static"
    Revalidate(seconds) => "revalidate:" + seconds.to_string()
  }
}

///|
/// Renders one boundary kind into the HTML attribute value used by placeholders.
fn render_boundary_attr(kind : BoundaryKind) -> String {
  match kind {
    ServerBoundary => "server"
    ClientBoundary => "client"
  }
}

///|
fn render_template_import_names(imports : Array[TemplateImport]) -> String {
  let names : Array[String] = []
  for imported in imports {
    names.push(@support.json_string(imported.local_name))
  }
  "[" + names.join(", ") + "]"
}

///|
fn render_resolve_template_import(
  component : VaporComponentRef,
  local_name : String,
) -> TemplateImport? {
  for imported in component.template_imports {
    if imported.local_name == local_name {
      return Some(imported)
    }
  }
  None
}

///|
fn render_merge_props(
  base : Array[(String, String)],
  overrides : Array[(String, String)],
) -> Array[(String, String)] {
  let merged = @support.clone_array(base)
  for entry in overrides {
    let mut replaced = false
    for i = 0; i < merged.length(); i = i + 1 {
      if merged[i].0 == entry.0 {
        merged[i] = entry
        replaced = true
      }
    }
    if not(replaced) {
      merged.push(entry)
    }
  }
  merged
}
