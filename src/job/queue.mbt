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
  jobs.push(enqueued_job(definition~, payload~, run_at~, attempts=0))
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
/// Applies Rails-like `retry_on` / `discard_on` policies to one failed job.
pub fn handle_job_failure(
  job : EnqueuedJob,
  error_name : String,
  now : String,
) -> JobFailureOutcome {
  match find_failure_policy(job.failure_policies, error_name) {
    Some(policy) => apply_failure_policy(job, policy, now)
    None =>
      match retry_job(job, now) {
        Some(next_job) => Retried(next_job)
        None => Unhandled(job)
      }
  }
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

///|
fn find_failure_policy(
  policies : Array[JobFailurePolicy],
  error_name : String,
) -> JobFailurePolicy? {
  let mut index = policies.length()
  while index > 0 {
    index -= 1
    if policies[index].matches(error_name) {
      return Some(policies[index])
    }
  }
  None
}

///|
fn apply_failure_policy(
  job : EnqueuedJob,
  policy : JobFailurePolicy,
  now : String,
) -> JobFailureOutcome {
  match policy.disposition {
    DiscardJob => Discarded(job)
    RetryJob =>
      match policy.attempts {
        Some(limit) => {
          let executions = job.attempts + 1
          if executions >= limit {
            RetryStopped(job)
          } else {
            Retried(build_retry_job(job, policy, now, executions))
          }
        }
        None => Retried(build_retry_job(job, policy, now, job.attempts + 1))
      }
  }
}

///|
fn build_retry_job(
  job : EnqueuedJob,
  policy : JobFailurePolicy,
  now : String,
  executions : Int,
) -> EnqueuedJob {
  let next_queue = match policy.queue {
    Some(queue) => queue
    None => job.queue
  }
  let next_run_at = schedule_retry_at(
    now,
    determine_retry_delay_seconds(policy.wait, executions),
  )
  { ..job, queue: next_queue, run_at: next_run_at, attempts: job.attempts + 1 }
}

///|
fn determine_retry_delay_seconds(wait : RetryWait, executions : Int) -> Int {
  match wait {
    FixedSeconds(seconds) => seconds
    PolynomiallyLonger => int_power(executions, 4) + 2
  }
}

///|
fn int_power(base : Int, exponent : Int) -> Int {
  let mut value = 1
  let mut remaining = exponent
  while remaining > 0 {
    value *= base
    remaining -= 1
  }
  value
}

///|
fn schedule_retry_at(now : String, delay_seconds : Int) -> String {
  if now.length() == 0 || delay_seconds <= 0 {
    return now
  }
  match parse_utc_timestamp(now) {
    Some(timestamp) =>
      format_utc_timestamp(add_seconds(timestamp, delay_seconds))
    None => now
  }
}
