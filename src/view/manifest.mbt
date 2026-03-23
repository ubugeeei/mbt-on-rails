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
  let sources : Array[String] = [page.component.source_path]
  for layout in page.layouts {
    sources.push(layout.file_path)
  }
  for island in page.client_islands {
    sources.push(island.source_path)
  }
  let json_sources : Array[String] = []
  for source in sources {
    json_sources.push(@support.json_string(source))
  }
  "[" + json_sources.join(", ") + "]"
}

///|
/// Renders the server action manifest consumed by the client bridge.
pub fn render_server_action_manifest(actions : Array[ServerAction]) -> String {
  let entries : Array[String] = []
  for action in actions {
    entries.push(
      "{" +
      "\"name\": " +
      @support.json_string(action.name) +
      ", \"route\": " +
      @support.json_string(action.route) +
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
