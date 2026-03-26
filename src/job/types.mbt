///|
/// Describes one background job and its contract.
pub struct JobDefinition {
  name : String
  queue : String
  argument_types : Array[(String, String)]
  retry_limit : Int
  unique_key : String?
  failure_policies : Array[JobFailurePolicy]
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
  failure_policies : Array[JobFailurePolicy]
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
/// Describes the wait strategy used when retrying a failed job.
pub enum RetryWait {
  FixedSeconds(Int)
  PolynomiallyLonger
} derive(Eq, Show)

///|
/// Describes how a failure handler reacts to a matching exception name.
pub enum FailureDisposition {
  RetryJob
  DiscardJob
} derive(Eq, Show)

///|
/// Describes one retry/discard policy attached to a job definition.
pub struct JobFailurePolicy {
  exception_names : Array[String]
  disposition : FailureDisposition
  attempts : Int?
  wait : RetryWait
  queue : String?
  report : Bool
}

///|
/// Describes the result of applying a failure policy to one job execution.
pub enum JobFailureOutcome {
  Retried(EnqueuedJob)
  Discarded(EnqueuedJob)
  RetryStopped(EnqueuedJob)
  Unhandled(EnqueuedJob)
}

///|
/// Builds a job definition.
#label_migration(name, allow_positional=true)
#label_migration(queue, allow_positional=true)
#label_migration(argument_types, allow_positional=true)
pub fn job(
  name~ : String,
  queue~ : String,
  argument_types~ : Array[(String, String)],
  retry_limit? : Int = 0,
  unique_key? : String? = None,
  failure_policies? : Array[JobFailurePolicy] = [],
) -> JobDefinition {
  { name, queue, argument_types, retry_limit, unique_key, failure_policies }
}

///|
/// Builds an empty logical job queue.
#label_migration(name, allow_positional=true)
pub fn job_queue(name~ : String) -> JobQueue {
  { name, jobs: [] }
}

///|
/// Builds one enqueued job payload from a job definition.
#label_migration(definition, allow_positional=true)
#label_migration(payload, allow_positional=true)
#label_migration(run_at, allow_positional=true)
#label_migration(attempts, allow_positional=true)
pub fn enqueued_job(
  definition~ : JobDefinition,
  payload~ : Array[(String, String)],
  run_at~ : String,
  attempts~ : Int,
) -> EnqueuedJob {
  {
    name: definition.name,
    queue: definition.queue,
    payload,
    run_at,
    attempts,
    retry_limit: definition.retry_limit,
    unique_key: definition.unique_key,
    failure_policies: definition.failure_policies,
  }
}

///|
/// Builds a fixed wait strategy in seconds.
#label_migration(seconds, allow_positional=true)
pub fn fixed_wait(seconds~ : Int) -> RetryWait {
  FixedSeconds(seconds)
}

///|
/// Builds the Rails-like `:polynomially_longer` wait strategy.
pub fn polynomially_longer() -> RetryWait {
  PolynomiallyLonger
}

///|
/// Builds a `retry_on` failure policy.
#label_migration(exception_name, allow_positional=true)
pub fn retry_on(
  exception_name~ : String,
  attempts? : Int = 5,
  wait? : RetryWait = FixedSeconds(3),
  queue? : String? = None,
  report? : Bool = false,
) -> JobFailurePolicy {
  {
    exception_names: [exception_name],
    disposition: RetryJob,
    attempts: Some(attempts),
    wait,
    queue,
    report,
  }
}

///|
/// Builds a `discard_on` failure policy.
#label_migration(exception_name, allow_positional=true)
pub fn discard_on(
  exception_name~ : String,
  report? : Bool = false,
) -> JobFailurePolicy {
  {
    exception_names: [exception_name],
    disposition: DiscardJob,
    attempts: None,
    wait: FixedSeconds(0),
    queue: None,
    report,
  }
}

///|
/// Attaches one failure policy to a job definition.
pub fn JobDefinition::with_failure_policy(
  self : JobDefinition,
  policy : JobFailurePolicy,
) -> JobDefinition {
  let failure_policies = @support.clone_array(self.failure_policies)
  failure_policies.push(policy)
  { ..self, failure_policies }
}

///|
/// Chainable `retry_on` builder for jobs.
pub fn JobDefinition::retry_on(
  self : JobDefinition,
  exception_name : String,
  attempts? : Int = 5,
  wait? : RetryWait = FixedSeconds(3),
  queue? : String? = None,
  report? : Bool = false,
) -> JobDefinition {
  self.with_failure_policy(
    retry_on(
      exception_name=exception_name,
      attempts=attempts,
      wait=wait,
      queue=queue,
      report=report,
    ),
  )
}

///|
/// Chainable `discard_on` builder for jobs.
pub fn JobDefinition::discard_on(
  self : JobDefinition,
  exception_name : String,
  report? : Bool = false,
) -> JobDefinition {
  self.with_failure_policy(
    discard_on(exception_name=exception_name, report=report),
  )
}

///|
/// Returns whether a failure policy handles the supplied error name.
pub fn JobFailurePolicy::matches(
  self : JobFailurePolicy,
  error_name : String,
) -> Bool {
  self.exception_names.contains(error_name)
}
