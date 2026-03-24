///|
/// Returns the manual hydration mode.
pub fn hydrate_manual() -> HydrationMode {
  Manual
}

///|
/// Returns the eager-on-load hydration mode.
pub fn hydrate_load() -> HydrationMode {
  Load
}

///|
/// Returns the idle-time hydration mode.
pub fn hydrate_idle() -> HydrationMode {
  Idle
}

///|
/// Returns the viewport-visible hydration mode.
pub fn hydrate_visible() -> HydrationMode {
  Visible
}

///|
/// Returns a media-query hydration mode.
pub fn hydrate_media(query : String) -> HydrationMode {
  Media(query)
}

///|
/// Returns the client-only hydration mode.
pub fn hydrate_only() -> HydrationMode {
  Only
}

///|
/// Returns the server-deferred hydration mode.
pub fn defer_on_server() -> HydrationMode {
  ServerDefer
}

///|
/// Returns the default dynamic page mode.
pub fn dynamic_auto() -> DynamicMode {
  Auto
}

///|
/// Returns the force-dynamic page mode.
pub fn dynamic_force_dynamic() -> DynamicMode {
  ForceDynamic
}

///|
/// Returns the force-static page mode.
pub fn dynamic_force_static() -> DynamicMode {
  ForceStatic
}

///|
/// Returns a revalidation-based page mode.
pub fn dynamic_revalidate(seconds : Int) -> DynamicMode {
  Revalidate(seconds)
}
