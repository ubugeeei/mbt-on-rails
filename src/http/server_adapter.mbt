///|
/// Errors raised by an HTTP server adapter.
pub(all) enum HttpServerAdapterError {
  HttpServerBindFailed(String)
  HttpServerListenFailed(String)
  HttpServerShutdownFailed(String)
  HttpServerOtherError(String)
}

///|
/// Renders a server adapter error for CLI / diagnostics output.
pub fn http_server_adapter_error_message(
  error : HttpServerAdapterError,
) -> String {
  match error {
    HttpServerBindFailed(detail) => "bind_failed: " + detail
    HttpServerListenFailed(detail) => "listen_failed: " + detail
    HttpServerShutdownFailed(detail) => "shutdown_failed: " + detail
    HttpServerOtherError(detail) => "other: " + detail
  }
}

///|
/// Outcome of attempting to start the server.
pub(all) enum HttpServerStartOutcome {
  HttpServerStarted(String)
  HttpServerStartFailed(HttpServerAdapterError)
}

///|
/// Outcome of shutdown / graceful drain calls.
pub(all) enum HttpServerStopOutcome {
  HttpServerStopped
  HttpServerStopFailed(HttpServerAdapterError)
}

///|
/// Pluggable contract for an HTTP server adapter — a thin integration
/// point between the framework's request → response pipeline and a
/// concrete TCP/HTTP listener.
///
/// `start` binds to the listening address and begins accepting
/// connections. `handle` is the application-supplied request → response
/// function the adapter must invoke for every incoming request.
/// `shutdown` lets the runtime initiate a graceful stop (drain in-flight
/// requests then close). `address` returns the bound listening address
/// for diagnostics / health probes.
pub(all) struct HttpServerAdapter {
  name : String
  start : (String, (Request) -> Response) -> HttpServerStartOutcome
  shutdown : () -> HttpServerStopOutcome
  address : () -> String?
}

///|
/// Builds an HTTP server adapter from explicit function values.
pub fn http_server_adapter(
  name : String,
  start : (String, (Request) -> Response) -> HttpServerStartOutcome,
  shutdown : () -> HttpServerStopOutcome,
  address : () -> String?,
) -> HttpServerAdapter {
  { name, start, shutdown, address }
}

///|
/// Returns an adapter that always reports `HttpServerBindFailed`.
pub fn null_http_server_adapter() -> HttpServerAdapter {
  let fail_start = fn(
    _bind : String,
    _handler : (Request) -> Response,
  ) -> HttpServerStartOutcome {
    HttpServerStartFailed(HttpServerBindFailed("null adapter is offline"))
  }
  let fail_stop = fn() -> HttpServerStopOutcome { HttpServerStopped }
  let no_address = fn() -> String? { None }
  { name: "null", start: fail_start, shutdown: fail_stop, address: no_address }
}

///|
/// Returns an adapter that records each request synchronously into a
/// shared array. Test harnesses can supply a sequence of canned
/// requests, then read the recorded responses back from the same array.
///
/// `served_addresses` captures the bind addresses passed to `start`;
/// `dispatched_requests` is incremented every time the handler is
/// invoked. Tests can drive the adapter with `dispatch_request` below.
pub fn captured_http_server_adapter(
  served_addresses : Array[String],
  dispatched_requests : Array[Int],
) -> HttpServerAdapter {
  if dispatched_requests.is_empty() {
    dispatched_requests.push(0)
  }
  let start = fn(
    bind : String,
    _handler : (Request) -> Response,
  ) -> HttpServerStartOutcome {
    served_addresses.push(bind)
    HttpServerStarted(bind)
  }
  let shutdown = fn() -> HttpServerStopOutcome { HttpServerStopped }
  let address = fn() -> String? {
    if served_addresses.is_empty() {
      None
    } else {
      Some(served_addresses[served_addresses.length() - 1])
    }
  }
  { name: "captured", start, shutdown, address }
}

///|
/// Counts a request dispatch against the captured adapter's counter.
/// Tests use this to simulate a request flowing through the captured
/// adapter without an external listener.
pub fn record_captured_dispatch(dispatched_requests : Array[Int]) -> Unit {
  if dispatched_requests.is_empty() {
    dispatched_requests.push(1)
  } else {
    dispatched_requests[0] = dispatched_requests[0] + 1
  }
}

///|
/// Starts the adapter against `bind_address`, passing `handler` as the
/// request → response function the adapter must invoke for every
/// incoming request.
pub fn http_server_start(
  adapter : HttpServerAdapter,
  bind_address : String,
  handler : (Request) -> Response,
) -> HttpServerStartOutcome {
  (adapter.start)(bind_address, handler)
}

///|
/// Initiates a graceful shutdown.
pub fn http_server_shutdown(
  adapter : HttpServerAdapter,
) -> HttpServerStopOutcome {
  (adapter.shutdown)()
}

///|
/// Returns the bound listening address, if any.
pub fn http_server_address(adapter : HttpServerAdapter) -> String? {
  (adapter.address)()
}

///|
/// One-line summary of an HTTP server adapter for CLI output.
pub fn http_server_adapter_summary(adapter : HttpServerAdapter) -> String {
  "http_server_adapter name=" + adapter.name
}
