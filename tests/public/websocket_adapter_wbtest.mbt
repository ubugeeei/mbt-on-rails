///|
fn sample_broadcast() -> CableBroadcast {
  cable_broadcast(
    cable_channel("ChatChannel", "room:lobby", []),
    "{\"hello\":\"world\"}",
    "application/json",
  )
}

///|
test "null_websocket_adapter reports connection_failed for every call" {
  let adapter = null_websocket_adapter()
  assert_eq(websocket_adapter_summary(adapter), "websocket_adapter name=null")
  match websocket_broadcast(adapter, sample_broadcast()) {
    WebSocketBroadcasted(_) => assert_true(false)
    WebSocketBroadcastFailed(error) =>
      assert_eq(
        websocket_adapter_error_message(error),
        "connection_failed: null adapter is offline",
      )
  }
  match websocket_subscribe(adapter, "ChatChannel", "conn-1") {
    WebSocketSubscriptionAcknowledged => assert_true(false)
    WebSocketSubscriptionFailed(error) =>
      assert_eq(
        websocket_adapter_error_message(error),
        "connection_failed: null adapter is offline",
      )
  }
  match websocket_close(adapter) {
    WebSocketSubscriptionAcknowledged => assert_true(true)
    WebSocketSubscriptionFailed(_) => assert_true(false)
  }
}

///|
test "websocket_adapter_error_message renders every variant" {
  assert_eq(
    websocket_adapter_error_message(WebSocketConnectionFailed("down")),
    "connection_failed: down",
  )
  assert_eq(
    websocket_adapter_error_message(WebSocketHandshakeFailed("bad upgrade")),
    "handshake_failed: bad upgrade",
  )
  assert_eq(
    websocket_adapter_error_message(WebSocketRejected("forbidden")),
    "rejected: forbidden",
  )
  assert_eq(
    websocket_adapter_error_message(WebSocketProtocolError("bad frame")),
    "protocol_error: bad frame",
  )
  assert_eq(
    websocket_adapter_error_message(WebSocketOtherError("misc")),
    "other: misc",
  )
}

///|
test "captured_websocket_adapter records broadcasts and subscriptions" {
  let broadcasts : Array[Int] = []
  let subscriptions : Array[Int] = []
  let adapter = captured_websocket_adapter(broadcasts, subscriptions)
  match websocket_broadcast(adapter, sample_broadcast()) {
    WebSocketBroadcasted(count) => assert_eq(count, 1)
    WebSocketBroadcastFailed(_) => assert_true(false)
  }
  match websocket_subscribe(adapter, "ChatChannel", "conn-1") {
    WebSocketSubscriptionAcknowledged => assert_true(true)
    WebSocketSubscriptionFailed(_) => assert_true(false)
  }
  match websocket_subscribe(adapter, "ChatChannel", "conn-2") {
    WebSocketSubscriptionAcknowledged => assert_true(true)
    WebSocketSubscriptionFailed(_) => assert_true(false)
  }
  match websocket_unsubscribe(adapter, "ChatChannel", "conn-1") {
    WebSocketSubscriptionAcknowledged => assert_true(true)
    WebSocketSubscriptionFailed(_) => assert_true(false)
  }
  assert_eq(broadcasts[0], 1)
  assert_eq(subscriptions[0], 2)
}
