///|
fn echo_handler(req : Request) -> Response {
  ok_text("echo " + req.path)
}

///|
test "null_http_server_adapter always reports bind_failed" {
  let adapter = null_http_server_adapter()
  assert_eq(
    http_server_adapter_summary(adapter),
    "http_server_adapter name=null",
  )
  match http_server_start(adapter, "0.0.0.0:3000", echo_handler) {
    HttpServerStarted(_) => assert_true(false)
    HttpServerStartFailed(error) =>
      assert_eq(
        http_server_adapter_error_message(error),
        "bind_failed: null adapter is offline",
      )
  }
  match http_server_shutdown(adapter) {
    HttpServerStopped => assert_true(true)
    HttpServerStopFailed(_) => assert_true(false)
  }
  assert_true(http_server_address(adapter) is None)
}

///|
test "http_server_adapter_error_message renders every variant" {
  assert_eq(
    http_server_adapter_error_message(HttpServerBindFailed("port in use")),
    "bind_failed: port in use",
  )
  assert_eq(
    http_server_adapter_error_message(HttpServerListenFailed("accept failed")),
    "listen_failed: accept failed",
  )
  assert_eq(
    http_server_adapter_error_message(HttpServerShutdownFailed("timeout")),
    "shutdown_failed: timeout",
  )
  assert_eq(
    http_server_adapter_error_message(HttpServerOtherError("misc")),
    "other: misc",
  )
}

///|
test "captured_http_server_adapter records bind addresses and dispatches" {
  let served : Array[String] = []
  let dispatches : Array[Int] = []
  let adapter = captured_http_server_adapter(served, dispatches)
  match http_server_start(adapter, "127.0.0.1:8080", echo_handler) {
    HttpServerStarted(addr) => assert_eq(addr, "127.0.0.1:8080")
    HttpServerStartFailed(_) => assert_true(false)
  }
  match http_server_address(adapter) {
    Some(addr) => assert_eq(addr, "127.0.0.1:8080")
    None => assert_true(false)
  }
  record_captured_dispatch(dispatches)
  record_captured_dispatch(dispatches)
  record_captured_dispatch(dispatches)
  assert_eq(dispatches[0], 3)
  assert_eq(served.length(), 1)
  match http_server_shutdown(adapter) {
    HttpServerStopped => assert_true(true)
    HttpServerStopFailed(_) => assert_true(false)
  }
}
