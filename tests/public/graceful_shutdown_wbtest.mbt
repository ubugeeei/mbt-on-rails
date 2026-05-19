///|
test "shutdown coordinator starts in ShutdownAccepting" {
  let drain_calls : Array[String] = []
  let stop_calls : Array[Int] = []
  let coord = shutdown_coordinator(fn(reason) { drain_calls.push(reason) }, fn() {
    stop_calls.push(1)
  })
  match shutdown_phase(coord) {
    ShutdownAccepting => assert_true(true)
    _ => assert_true(false)
  }
  assert_true(shutdown_should_accept(coord))
  assert_false(shutdown_is_stopped(coord))
  assert_eq(shutdown_coordinator_summary(coord), "shutdown phase=accepting")
}

///|
test "shutdown_begin_drain transitions once and fires the drain hook" {
  let drain_calls : Array[String] = []
  let stop_calls : Array[Int] = []
  let coord = shutdown_coordinator(fn(reason) { drain_calls.push(reason) }, fn() {
    stop_calls.push(1)
  })
  shutdown_begin_drain(coord, "SIGTERM")
  match shutdown_phase(coord) {
    ShutdownDraining(reason) => assert_eq(reason, "SIGTERM")
    _ => assert_true(false)
  }
  assert_false(shutdown_should_accept(coord))
  assert_eq(drain_calls.length(), 1)
  // Second begin_drain is a no-op.
  shutdown_begin_drain(coord, "second")
  assert_eq(drain_calls.length(), 1)
}

///|
test "shutdown_complete transitions to ShutdownStopped and fires once" {
  let drain_calls : Array[String] = []
  let stop_calls : Array[Int] = []
  let coord = shutdown_coordinator(fn(reason) { drain_calls.push(reason) }, fn() {
    stop_calls.push(1)
  })
  shutdown_begin_drain(coord, "deploy")
  shutdown_complete(coord)
  match shutdown_phase(coord) {
    ShutdownStopped => assert_true(true)
    _ => assert_true(false)
  }
  assert_true(shutdown_is_stopped(coord))
  assert_eq(stop_calls.length(), 1)
  // Second complete is a no-op.
  shutdown_complete(coord)
  assert_eq(stop_calls.length(), 1)
}

///|
test "shutdown_phase_summary renders each phase" {
  assert_eq(shutdown_phase_summary(ShutdownAccepting), "accepting")
  assert_eq(shutdown_phase_summary(ShutdownDraining("oom")), "draining(oom)")
  assert_eq(shutdown_phase_summary(ShutdownStopped), "stopped")
}
