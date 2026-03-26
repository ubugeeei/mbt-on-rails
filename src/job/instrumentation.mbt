///|
/// Enqueues one ready job and records an Active Job enqueue event.
pub fn enqueue_now_with_notifications(
  queue~ : JobQueue,
  definition~ : JobDefinition,
  payload~ : Array[(String, String)],
  notifications~ : @support.Notifications,
) -> (JobQueue, @support.Notifications) {
  let updated_queue = enqueue_now(queue, definition, payload)
  let updated = notifications.instrument(name="enqueue.active_job", payload=[
    ("job", definition.name),
    ("queue", definition.queue),
    ("scheduled_at", "now"),
  ])
  (updated_queue, updated)
}

///|
/// Enqueues one future job and records a scheduled enqueue event.
pub fn enqueue_at_with_notifications(
  queue~ : JobQueue,
  definition~ : JobDefinition,
  payload~ : Array[(String, String)],
  run_at~ : String,
  notifications~ : @support.Notifications,
) -> (JobQueue, @support.Notifications) {
  let updated_queue = enqueue_at(queue, definition, payload, run_at)
  let updated = notifications.instrument(name="enqueue_at.active_job", payload=[
    ("job", definition.name),
    ("queue", definition.queue),
    ("scheduled_at", run_at),
  ])
  (updated_queue, updated)
}

///|
/// Returns ready jobs and records one perform-start event for each.
pub fn drain_ready_with_notifications(
  queue~ : JobQueue,
  now~ : String,
  notifications~ : @support.Notifications,
) -> (DrainedJobs, @support.Notifications) {
  let drained = drain_ready(queue, now)
  let mut updated = notifications
  for current in drained.ready {
    updated = updated.instrument(name="perform_start.active_job", payload=[
      ("job", current.name),
      ("queue", current.queue),
      (
        "scheduled_at",
        if current.run_at.length() == 0 {
          "now"
        } else {
          current.run_at
        },
      ),
    ])
  }
  (drained, updated)
}

///|
/// Retries one job and records whether retrying continued or stopped.
pub fn retry_job_with_notifications(
  job~ : EnqueuedJob,
  next_run_at~ : String,
  notifications~ : @support.Notifications,
) -> (EnqueuedJob?, @support.Notifications) {
  match retry_job(job, next_run_at) {
    Some(next_job) =>
      (
        Some(next_job),
        notifications.instrument(name="enqueue_retry.active_job", payload=[
          ("job", job.name),
          ("queue", job.queue),
          ("attempts", next_job.attempts.to_string()),
          ("scheduled_at", next_run_at),
        ]),
      )
    None =>
      (
        None,
        notifications.instrument(name="retry_stopped.active_job", payload=[
          ("job", job.name),
          ("queue", job.queue),
          ("attempts", job.attempts.to_string()),
        ]),
      )
  }
}

///|
/// Applies Rails-like failure policies and records retry/discard notifications.
pub fn handle_job_failure_with_notifications(
  job~ : EnqueuedJob,
  error_name~ : String,
  now~ : String,
  notifications~ : @support.Notifications,
) -> (JobFailureOutcome, @support.Notifications) {
  match handle_job_failure(job, error_name, now) {
    Retried(next_job) =>
      (
        Retried(next_job),
        notifications.instrument(name="enqueue_retry.active_job", payload=[
          ("job", job.name),
          ("queue", next_job.queue),
          ("attempts", next_job.attempts.to_string()),
          (
            "scheduled_at",
            if next_job.run_at.length() == 0 {
              "now"
            } else {
              next_job.run_at
            },
          ),
          ("error", error_name),
        ]),
      )
    Discarded(current) =>
      (
        Discarded(current),
        notifications.instrument(name="discard.active_job", payload=[
          ("job", current.name),
          ("queue", current.queue),
          ("attempts", current.attempts.to_string()),
          ("error", error_name),
        ]),
      )
    RetryStopped(current) =>
      (
        RetryStopped(current),
        notifications.instrument(name="retry_stopped.active_job", payload=[
          ("job", current.name),
          ("queue", current.queue),
          ("attempts", current.attempts.to_string()),
          ("error", error_name),
        ]),
      )
    Unhandled(current) => (Unhandled(current), notifications)
  }
}
