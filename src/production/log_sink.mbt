///|
/// Errors raised when emitting a `LogEvent` to a `LogSink`.
pub(all) enum LogSinkError {
  LogSinkBackendUnavailable(String)
  LogSinkBufferOverflow(String)
  LogSinkOtherError(String)
}

///|
/// Renders a sink error as a CLI-friendly diagnostic string.
pub fn log_sink_error_message(error : LogSinkError) -> String {
  match error {
    LogSinkBackendUnavailable(detail) => "backend_unavailable: " + detail
    LogSinkBufferOverflow(detail) => "buffer_overflow: " + detail
    LogSinkOtherError(detail) => "other: " + detail
  }
}

///|
/// Outcome of one `log_sink_emit` call.
pub(all) enum LogSinkEmitOutcome {
  LogSinkEmitted
  LogSinkEmitFailed(LogSinkError)
}

///|
/// Pluggable contract for a structured-log sink.
///
/// `emit` ships one `LogEvent` to the sink. `close` releases any held
/// resource (file handle, network connection). Function-valued fields
/// mirror the shape of `SmtpAdapter` and `CacheAdapter` so concrete
/// sinks (stdout, file, network shipper) plug in uniformly.
pub(all) struct LogSink {
  name : String
  emit : (LogEvent) -> LogSinkEmitOutcome
  close : () -> LogSinkEmitOutcome
}

///|
/// Builds a log sink from explicit function values.
pub fn log_sink(
  name : String,
  emit : (LogEvent) -> LogSinkEmitOutcome,
  close : () -> LogSinkEmitOutcome,
) -> LogSink {
  { name, emit, close }
}

///|
/// Returns a sink that silently drops every event.
///
/// Useful as the default sink when logging is disabled and in tests
/// that want a no-op without standing up a buffer.
pub fn null_log_sink() -> LogSink {
  let emit = fn(_event : LogEvent) -> LogSinkEmitOutcome { LogSinkEmitted }
  let close = fn() -> LogSinkEmitOutcome { LogSinkEmitted }
  { name: "null", emit, close }
}

///|
/// Returns a sink that records every emitted `LogEvent` into the shared
/// `events` array so tests can inspect what would have been logged.
///
/// The sink and the caller share the array — push the array into the
/// closure once at construction time and read it back after exercising
/// the system under test.
pub fn captured_log_sink(events : Array[LogEvent]) -> LogSink {
  let emit = fn(event : LogEvent) -> LogSinkEmitOutcome {
    events.push(event)
    LogSinkEmitted
  }
  let close = fn() -> LogSinkEmitOutcome { LogSinkEmitted }
  { name: "captured", emit, close }
}

///|
/// Returns a sink that renders every event as a JSON line (via
/// `json_log`) and appends it to the shared `lines` buffer.
///
/// Mirrors how a stdout JSON-lines logger would write — each emit
/// produces exactly one line in the buffer. The buffer can then be
/// flushed to any concrete writer by the caller.
pub fn json_lines_log_sink(lines : Array[String]) -> LogSink {
  let emit = fn(event : LogEvent) -> LogSinkEmitOutcome {
    lines.push(json_log(event))
    LogSinkEmitted
  }
  let close = fn() -> LogSinkEmitOutcome { LogSinkEmitted }
  { name: "json_lines", emit, close }
}

///|
/// Emits one event through a sink.
pub fn log_sink_emit(sink : LogSink, event : LogEvent) -> LogSinkEmitOutcome {
  (sink.emit)(event)
}

///|
/// Closes a sink (releases any held resource).
pub fn log_sink_close(sink : LogSink) -> LogSinkEmitOutcome {
  (sink.close)()
}

///|
/// One-line summary of a log sink for CLI / diagnostics output.
pub fn log_sink_summary(sink : LogSink) -> String {
  "log_sink name=" + sink.name
}
