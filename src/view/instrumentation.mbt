///|
/// Renders one page and records Action View-style template/layout events.
pub fn render_page_with_notifications(
  page~ : PageModule,
  route_params~ : Array[(String, String)],
  loader_data~ : Array[(String, String)],
  actions~ : Array[ServerAction],
  notifications~ : @support.Notifications,
) -> (RenderedPage, @support.Notifications) {
  let rendered = render_page(page, route_params, loader_data, actions)
  let mut updated = notifications.instrument(
    name="render_template.action_view",
    payload=[
      ("identifier", page.file_path.as_string()),
      ("route_name", page.route_name),
      ("dynamic_mode", dynamic_mode_name(page.dynamic_mode)),
      ("island_count", page.client_islands.length().to_string()),
    ],
  )
  for layout in page.layouts {
    updated = updated.instrument(
      name="render_layout.action_view",
      payload=[
        ("identifier", layout.file_path.as_string()),
        ("layout", layout.name),
      ],
    )
  }
  (rendered, updated)
}

fn dynamic_mode_name(mode : DynamicMode) -> String {
  match mode {
    Auto => "auto"
    ForceDynamic => "force-dynamic"
    ForceStatic => "force-static"
    Revalidate(seconds) => "revalidate:" + seconds.to_string()
  }
}
