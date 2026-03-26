///|
/// Builds the cable channels configured by the demo app.
pub fn demo_cable_channels() -> Array[@cable.CableChannel] {
  [
    @cable.cable_channel("PostsChannel", "posts", ["post_id"]),
    @cable.cable_channel("NotificationsChannel", "notifications", ["user_id"]),
  ]
}
