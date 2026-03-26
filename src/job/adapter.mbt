///|
/// Renders one adapter in a CLI-friendly summary format.
pub fn job_adapter_summary(adapter : JobAdapter) -> String {
  "adapter " +
  adapter.name +
  " kind=" +
  render_job_adapter_kind(adapter.kind) +
  " queue_prefix=" +
  (match adapter.queue_prefix {
    Some(prefix) => prefix
    None => "-"
  }) +
  " persistent=" +
  (if adapter.persistent { "true" } else { "false" }) +
  " scheduling=" +
  (if adapter.supports_scheduling { "true" } else { "false" }) +
  " retries=" +
  (if adapter.supports_retries { "true" } else { "false" }) +
  " inline=" +
  (if adapter.inline_execution { "true" } else { "false" })
}

///|
/// Returns the effective queue name for one adapter-backed delivery.
pub fn JobAdapter::queue_name(self : JobAdapter, queue_name : String) -> String {
  match self.queue_prefix {
    Some(prefix) =>
      if prefix.length() == 0 {
        queue_name
      } else {
        prefix + ":" + queue_name
      }
    None => queue_name
  }
}

///|
/// Rewrites a definition so its queue matches the supplied adapter contract.
pub fn apply_job_adapter(
  definition : JobDefinition,
  adapter : JobAdapter,
) -> JobDefinition {
  { ..definition, queue: adapter.queue_name(definition.queue) }
}

///|
/// Enqueues one ready job using the supplied adapter contract.
pub fn enqueue_now_with_adapter(
  queue : JobQueue,
  definition : JobDefinition,
  payload : Array[(String, String)],
  adapter : JobAdapter,
) -> JobQueue {
  let adapted = apply_job_adapter(definition, adapter)
  let target_queue = if queue.name == adapted.queue {
    queue
  } else {
    { ..queue, name: adapted.queue }
  }
  enqueue_now(target_queue, adapted, payload)
}

///|
/// Enqueues one scheduled job using the supplied adapter contract.
pub fn enqueue_at_with_adapter(
  queue : JobQueue,
  definition : JobDefinition,
  payload : Array[(String, String)],
  run_at : String,
  adapter : JobAdapter,
) -> JobQueue {
  let adapted = apply_job_adapter(definition, adapter)
  let target_queue = if queue.name == adapted.queue {
    queue
  } else {
    { ..queue, name: adapted.queue }
  }
  enqueue_at(target_queue, adapted, payload, run_at)
}

///|
fn render_job_adapter_kind(kind : JobAdapterKind) -> String {
  match kind {
    InlineAdapter => "inline"
    AsyncAdapter => "async"
    TestAdapter => "test"
    SolidQueueAdapter => "solid_queue"
  }
}
