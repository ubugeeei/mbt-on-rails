///|
fn sample_log_event() -> LogEvent {
  log_event("info", "request handled", Some("req-42"), [("path", "/health")])
}

///|
test "null_log_sink swallows every event without error" {
  let sink = null_log_sink()
  assert_eq(log_sink_summary(sink), "log_sink name=null")
  match log_sink_emit(sink, sample_log_event()) {
    LogSinkEmitted => assert_true(true)
    LogSinkEmitFailed(_) => assert_true(false)
  }
  match log_sink_close(sink) {
    LogSinkEmitted => assert_true(true)
    LogSinkEmitFailed(_) => assert_true(false)
  }
}

///|
test "log_sink_error_message renders every variant for diagnostics" {
  assert_eq(
    log_sink_error_message(LogSinkBackendUnavailable("down")),
    "backend_unavailable: down",
  )
  assert_eq(
    log_sink_error_message(LogSinkBufferOverflow("queue full")),
    "buffer_overflow: queue full",
  )
  assert_eq(log_sink_error_message(LogSinkOtherError("misc")), "other: misc")
}

///|
test "captured_log_sink records every event into the shared buffer" {
  let events : Array[LogEvent] = []
  let sink = captured_log_sink(events)
  let _ = log_sink_emit(sink, sample_log_event())
  let _ = log_sink_emit(
    sink,
    log_event("error", "boom", None, [("code", "500")]),
  )
  assert_eq(events.length(), 2)
  assert_eq(events[0].level, "info")
  assert_eq(events[0].message, "request handled")
  assert_eq(events[1].level, "error")
  assert_true(events[1].request_id is None)
}

///|
test "json_lines_log_sink emits one JSON line per event" {
  let lines : Array[String] = []
  let sink = json_lines_log_sink(lines)
  let _ = log_sink_emit(sink, sample_log_event())
  let _ = log_sink_emit(
    sink,
    log_event("warn", "slow query", Some("req-7"), []),
  )
  assert_eq(lines.length(), 2)
  assert_eq(
    lines[0],
    "{\"level\": \"info\", \"message\": \"request handled\", \"request_id\": \"req-42\", \"metadata\": {\"path\": \"/health\"}}",
  )
  assert_eq(
    lines[1],
    "{\"level\": \"warn\", \"message\": \"slow query\", \"request_id\": \"req-7\", \"metadata\": {}}",
  )
}

///|
test "log_sink composes a fake driver that can fail and recover" {
  let attempts : Array[Int] = [0]
  let emit = fn(_event : LogEvent) -> LogSinkEmitOutcome {
    attempts[0] = attempts[0] + 1
    if attempts[0] == 1 {
      LogSinkEmitFailed(LogSinkBackendUnavailable("first attempt"))
    } else {
      LogSinkEmitted
    }
  }
  let close = fn() -> LogSinkEmitOutcome { LogSinkEmitted }
  let sink = log_sink("fake", emit, close)
  assert_eq(log_sink_summary(sink), "log_sink name=fake")
  match log_sink_emit(sink, sample_log_event()) {
    LogSinkEmitted => assert_true(false)
    LogSinkEmitFailed(error) =>
      assert_eq(
        log_sink_error_message(error),
        "backend_unavailable: first attempt",
      )
  }
  match log_sink_emit(sink, sample_log_event()) {
    LogSinkEmitted => assert_true(true)
    LogSinkEmitFailed(_) => assert_true(false)
  }
  assert_eq(attempts[0], 2)
}
