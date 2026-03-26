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
