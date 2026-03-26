///|
/// Stores one emitted runtime notification with a Rails-style event name.
pub struct NotificationEvent {
  name : String
  payload : Array[(String, String)]
}

///|
/// Collects emitted runtime notifications in the order they happened.
pub struct Notifications {
  events : Array[NotificationEvent]
}

///|
/// Builds an empty notification buffer.
pub fn notifications() -> Notifications {
  { events: [] }
}

///|
/// Builds one notification event descriptor.
pub fn notification_event(
  name~ : String,
  payload~ : Array[(String, String)],
) -> NotificationEvent {
  { name, payload }
}

///|
/// Appends one event to the buffer.
pub fn Notifications::append(
  self : Notifications,
  event : NotificationEvent,
) -> Notifications {
  let events = clone_array(self.events)
  events.push(event)
  { events, }
}

///|
/// Records one named event and its payload.
pub fn Notifications::instrument(
  self : Notifications,
  name~ : String,
  payload~ : Array[(String, String)],
) -> Notifications {
  self.append(notification_event(name~, payload~))
}

///|
/// Appends the contents of another buffer.
pub fn Notifications::merge(
  self : Notifications,
  other : Notifications,
) -> Notifications {
  let events = clone_array(self.events)
  for event in other.events {
    events.push(event)
  }
  { events, }
}

///|
/// Returns only events with an exact name match.
pub fn Notifications::named(
  self : Notifications,
  name : String,
) -> Array[NotificationEvent] {
  let matches : Array[NotificationEvent] = []
  for event in self.events {
    if event.name == name {
      matches.push(event)
    }
  }
  matches
}

///|
/// Returns only events whose names start with the supplied prefix.
pub fn Notifications::prefixed(
  self : Notifications,
  prefix : String,
) -> Array[NotificationEvent] {
  let matches : Array[NotificationEvent] = []
  for event in self.events {
    if event.name.has_prefix(prefix) {
      matches.push(event)
    }
  }
  matches
}

///|
/// Looks up one payload value by key.
pub fn NotificationEvent::payload_value(
  self : NotificationEvent,
  key : String,
) -> String? {
  find_entry(self.payload, key)
}

///|
/// Renders notifications in a compact debug-friendly format.
pub fn Notifications::summary(self : Notifications) -> String {
  let lines : Array[String] = []
  for event in self.events {
    lines.push(event.name + " " + entries_to_json(event.payload))
  }
  lines.join("\n")
}
