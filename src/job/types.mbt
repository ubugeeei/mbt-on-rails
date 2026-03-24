///|
/// Describes one background job and its contract.
pub struct JobDefinition {
  name : String
  queue : String
  argument_types : Array[(String, String)]
  retry_limit : Int
  unique_key : String?
}

///|
/// Represents one scheduled or ready job in a queue.
pub struct EnqueuedJob {
  name : String
  queue : String
  payload : Array[(String, String)]
  run_at : String
  attempts : Int
  retry_limit : Int
  unique_key : String?
}

///|
/// Stores the queued jobs for one logical queue.
pub struct JobQueue {
  name : String
  jobs : Array[EnqueuedJob]
}

///|
/// Stores the result of draining all currently-ready jobs.
pub struct DrainedJobs {
  queue : JobQueue
  ready : Array[EnqueuedJob]
}

///|
/// Builds a job definition.
pub fn job(
  name : String,
  queue : String,
  argument_types : Array[(String, String)],
  retry_limit : Int,
  unique_key : String?,
) -> JobDefinition {
  { name, queue, argument_types, retry_limit, unique_key }
}

///|
/// Builds an empty logical job queue.
pub fn job_queue(name : String) -> JobQueue {
  { name, jobs: [] }
}

///|
/// Builds one enqueued job payload from a job definition.
pub fn enqueued_job(
  definition : JobDefinition,
  payload : Array[(String, String)],
  run_at : String,
  attempts : Int,
) -> EnqueuedJob {
  {
    name: definition.name,
    queue: definition.queue,
    payload,
    run_at,
    attempts,
    retry_limit: definition.retry_limit,
    unique_key: definition.unique_key,
  }
}
