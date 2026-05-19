///|
/// Lifecycle phases of a process orchestrated by a `ShutdownCoordinator`.
///
/// `ShutdownAccepting` is the steady state — the process is taking new
/// traffic. `ShutdownDraining(reason)` means the runtime received a
/// shutdown signal (SIGTERM, deploy event, health-probe failure, etc.)
/// and is refusing new traffic while in-flight work finishes. `ShutdownStopped`
/// is the terminal state.
pub(all) enum ShutdownPhase {
  ShutdownAccepting
  ShutdownDraining(String)
  ShutdownStopped
}

///|
/// Renders a phase as a CLI-friendly diagnostic string.
pub fn shutdown_phase_summary(phase : ShutdownPhase) -> String {
  match phase {
    ShutdownAccepting => "accepting"
    ShutdownDraining(reason) => "draining(" + reason + ")"
    ShutdownStopped => "stopped"
  }
}

///|
/// Coordinates graceful shutdown across the running process.
///
/// `phase_ref` holds the current phase (single-element array used as a
/// mutable cell so the coordinator stays shareable between callers).
/// `on_drain` is invoked once when the coordinator transitions to
/// `ShutdownDraining` so callers can flush in-flight work; `on_stop`
/// runs once when the coordinator transitions to `ShutdownStopped`.
pub(all) struct ShutdownCoordinator {
  phase_ref : Array[ShutdownPhase]
  on_drain : (String) -> Unit
  on_stop : () -> Unit
}

///|
/// Builds a shutdown coordinator with the supplied drain / stop hooks.
pub fn shutdown_coordinator(
  on_drain : (String) -> Unit,
  on_stop : () -> Unit,
) -> ShutdownCoordinator {
  let phase_ref : Array[ShutdownPhase] = []
  phase_ref.push(ShutdownAccepting)
  { phase_ref, on_drain, on_stop }
}

///|
/// Returns the current phase.
pub fn shutdown_phase(coord : ShutdownCoordinator) -> ShutdownPhase {
  if coord.phase_ref.is_empty() {
    ShutdownAccepting
  } else {
    coord.phase_ref[0]
  }
}

///|
/// Returns `true` while the coordinator is still accepting new traffic.
///
/// Wire this into the request middleware or the load-balancer health
/// probe so the runtime stops admitting work as soon as shutdown is
/// announced.
pub fn shutdown_should_accept(coord : ShutdownCoordinator) -> Bool {
  match shutdown_phase(coord) {
    ShutdownAccepting => true
    _ => false
  }
}

///|
/// Returns `true` once the coordinator has reached `ShutdownStopped`.
pub fn shutdown_is_stopped(coord : ShutdownCoordinator) -> Bool {
  match shutdown_phase(coord) {
    ShutdownStopped => true
    _ => false
  }
}

///|
/// Transitions the coordinator to `ShutdownDraining` and runs the
/// `on_drain` hook once. Repeated calls are no-ops so signal handlers
/// can fire SIGTERM more than once safely.
pub fn shutdown_begin_drain(
  coord : ShutdownCoordinator,
  reason : String,
) -> Unit {
  match shutdown_phase(coord) {
    ShutdownAccepting => {
      coord.phase_ref[0] = ShutdownDraining(reason)
      (coord.on_drain)(reason)
    }
    _ => ()
  }
}

///|
/// Transitions the coordinator to `ShutdownStopped` and runs the
/// `on_stop` hook once. Skips the draining state if the coordinator
/// is still accepting (callers can force-stop a healthy process).
pub fn shutdown_complete(coord : ShutdownCoordinator) -> Unit {
  match shutdown_phase(coord) {
    ShutdownStopped => ()
    _ => {
      coord.phase_ref[0] = ShutdownStopped
      (coord.on_stop)()
    }
  }
}

///|
/// One-line summary of the coordinator state for CLI / log output.
pub fn shutdown_coordinator_summary(coord : ShutdownCoordinator) -> String {
  "shutdown phase=" + shutdown_phase_summary(shutdown_phase(coord))
}
