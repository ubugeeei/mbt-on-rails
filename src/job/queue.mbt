///|
/// Adds one immediately-ready job to a queue.
pub fn enqueue_now(
  queue : JobQueue,
  definition : JobDefinition,
  payload : Array[(String, String)],
) -> JobQueue {
  enqueue_at(queue, definition, payload, "")
}

///|
/// Adds one future job to a queue using a lexicographically sortable timestamp.
pub fn enqueue_at(
  queue : JobQueue,
  definition : JobDefinition,
  payload : Array[(String, String)],
  run_at : String,
) -> JobQueue {
  let jobs = @support.clone_array(queue.jobs)
  jobs.push(enqueued_job(definition, payload, run_at, 0))
  { ..queue, jobs, }
}

///|
/// Returns whether a job should be executed at the given timestamp.
pub fn job_ready(job : EnqueuedJob, now : String) -> Bool {
  job.run_at.length() == 0 || lexicographic_lte(job.run_at, now)
}

///|
/// Removes ready jobs from a queue and returns them separately.
pub fn drain_ready(queue : JobQueue, now : String) -> DrainedJobs {
  let waiting : Array[EnqueuedJob] = []
  let ready : Array[EnqueuedJob] = []
  for current in queue.jobs {
    if job_ready(current, now) {
      ready.push(current)
    } else {
      waiting.push(current)
    }
  }
  { queue: { ..queue, jobs: waiting }, ready }
}

///|
/// Produces a retried job when the retry budget is not exhausted.
pub fn retry_job(job : EnqueuedJob, next_run_at : String) -> EnqueuedJob? {
  if job.attempts + 1 > job.retry_limit {
    return None
  }
  Some({ ..job, run_at: next_run_at, attempts: job.attempts + 1 })
}

///|
/// Renders one queue in a CLI-friendly summary format.
pub fn job_summary(queue : JobQueue) -> String {
  let lines : Array[String] = ["queue " + queue.name]
  for current in queue.jobs {
    lines.push(
      "  - " +
      current.name +
      " attempts=" +
      current.attempts.to_string() +
      " run_at=" +
      (if current.run_at.length() == 0 { "now" } else { current.run_at }) +
      " payload=" +
      @support.entries_to_json(current.payload),
    )
  }
  lines.join("\n")
}

///|
/// Compares two sortable timestamps without relying on platform date helpers.
fn lexicographic_lte(left : String, right : String) -> Bool {
  let left_chars = left.to_array()
  let right_chars = right.to_array()
  let limit = if left_chars.length() < right_chars.length() {
    left_chars.length()
  } else {
    right_chars.length()
  }
  for index in 0..<limit {
    if left_chars[index] < right_chars[index] {
      return true
    }
    if left_chars[index] > right_chars[index] {
      return false
    }
  }
  left_chars.length() <= right_chars.length()
}
