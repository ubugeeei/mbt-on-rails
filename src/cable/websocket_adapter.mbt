///|
/// Errors raised by a WebSocket adapter.
pub(all) enum WebSocketAdapterError {
  WebSocketConnectionFailed(String)
  WebSocketHandshakeFailed(String)
  WebSocketRejected(String)
  WebSocketProtocolError(String)
  WebSocketOtherError(String)
}

///|
/// Renders a WebSocket adapter error for CLI / diagnostics.
pub fn websocket_adapter_error_message(error : WebSocketAdapterError) -> String {
  match error {
    WebSocketConnectionFailed(detail) => "connection_failed: " + detail
    WebSocketHandshakeFailed(detail) => "handshake_failed: " + detail
    WebSocketRejected(detail) => "rejected: " + detail
    WebSocketProtocolError(detail) => "protocol_error: " + detail
    WebSocketOtherError(detail) => "other: " + detail
  }
}

///|
/// Outcome of attempting to publish a broadcast through the adapter.
pub(all) enum WebSocketBroadcastOutcome {
  WebSocketBroadcasted(Int)
  WebSocketBroadcastFailed(WebSocketAdapterError)
}

///|
/// Outcome of subscribe / unsubscribe / close calls.
pub(all) enum WebSocketSubscriptionOutcome {
  WebSocketSubscriptionAcknowledged
  WebSocketSubscriptionFailed(WebSocketAdapterError)
}

///|
/// Pluggable contract for an Action Cable-style WebSocket adapter.
///
/// `broadcast` publishes a message to every subscriber of a channel.
/// `subscribe` / `unsubscribe` manage one connection's interest in a
/// channel; both return acknowledgement / failure outcomes. `close`
/// releases adapter-held state (relay session, in-memory queue, etc.).
pub(all) struct WebSocketAdapter {
  name : String
  broadcast : (CableBroadcast) -> WebSocketBroadcastOutcome
  subscribe : (String, String) -> WebSocketSubscriptionOutcome
  unsubscribe : (String, String) -> WebSocketSubscriptionOutcome
  close : () -> WebSocketSubscriptionOutcome
}

///|
/// Builds a WebSocket adapter from explicit function values.
pub fn websocket_adapter(
  name : String,
  broadcast : (CableBroadcast) -> WebSocketBroadcastOutcome,
  subscribe : (String, String) -> WebSocketSubscriptionOutcome,
  unsubscribe : (String, String) -> WebSocketSubscriptionOutcome,
  close : () -> WebSocketSubscriptionOutcome,
) -> WebSocketAdapter {
  { name, broadcast, subscribe, unsubscribe, close }
}

///|
/// Returns an adapter that reports `WebSocketConnectionFailed` for
/// every call.
pub fn null_websocket_adapter() -> WebSocketAdapter {
  let fail_broadcast = fn(_b : CableBroadcast) -> WebSocketBroadcastOutcome {
    WebSocketBroadcastFailed(
      WebSocketConnectionFailed("null adapter is offline"),
    )
  }
  let fail_subscription = fn(
    _channel : String,
    _connection : String,
  ) -> WebSocketSubscriptionOutcome {
    WebSocketSubscriptionFailed(
      WebSocketConnectionFailed("null adapter is offline"),
    )
  }
  let close_self = fn() -> WebSocketSubscriptionOutcome {
    WebSocketSubscriptionAcknowledged
  }
  {
    name: "null",
    broadcast: fail_broadcast,
    subscribe: fail_subscription,
    unsubscribe: fail_subscription,
    close: close_self,
  }
}

///|
/// Returns an adapter that records every broadcast and subscription
/// into shared counters so integration tests can verify wiring without
/// an external Redis / pubsub backend.
pub fn captured_websocket_adapter(
  broadcast_counter : Array[Int],
  subscribe_counter : Array[Int],
) -> WebSocketAdapter {
  if broadcast_counter.is_empty() {
    broadcast_counter.push(0)
  }
  if subscribe_counter.is_empty() {
    subscribe_counter.push(0)
  }
  let broadcast = fn(_b : CableBroadcast) -> WebSocketBroadcastOutcome {
    broadcast_counter[0] = broadcast_counter[0] + 1
    WebSocketBroadcasted(1)
  }
  let subscribe = fn(
    _channel : String,
    _connection : String,
  ) -> WebSocketSubscriptionOutcome {
    subscribe_counter[0] = subscribe_counter[0] + 1
    WebSocketSubscriptionAcknowledged
  }
  let unsubscribe = fn(
    _channel : String,
    _connection : String,
  ) -> WebSocketSubscriptionOutcome {
    WebSocketSubscriptionAcknowledged
  }
  let close = fn() -> WebSocketSubscriptionOutcome {
    WebSocketSubscriptionAcknowledged
  }
  { name: "captured", broadcast, subscribe, unsubscribe, close }
}

///|
/// Issues a broadcast against an adapter.
pub fn websocket_broadcast(
  adapter : WebSocketAdapter,
  broadcast : CableBroadcast,
) -> WebSocketBroadcastOutcome {
  (adapter.broadcast)(broadcast)
}

///|
/// Subscribes one connection to a channel.
pub fn websocket_subscribe(
  adapter : WebSocketAdapter,
  channel_name : String,
  connection_id : String,
) -> WebSocketSubscriptionOutcome {
  (adapter.subscribe)(channel_name, connection_id)
}

///|
/// Unsubscribes one connection from a channel.
pub fn websocket_unsubscribe(
  adapter : WebSocketAdapter,
  channel_name : String,
  connection_id : String,
) -> WebSocketSubscriptionOutcome {
  (adapter.unsubscribe)(channel_name, connection_id)
}

///|
/// Closes the adapter (releases any held connection or pubsub session).
pub fn websocket_close(
  adapter : WebSocketAdapter,
) -> WebSocketSubscriptionOutcome {
  (adapter.close)()
}

///|
/// One-line summary of a WebSocket adapter for CLI / diagnostics output.
pub fn websocket_adapter_summary(adapter : WebSocketAdapter) -> String {
  "websocket_adapter name=" + adapter.name
}
