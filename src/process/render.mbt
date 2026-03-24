///|
/// Builds a web process definition.
pub fn web_process(
  name : String,
  command : String,
  concurrency : Int,
  env_keys : Array[String],
) -> ProcessDefinition {
  process_definition(name, WebRole, command, concurrency, [], env_keys)
}

///|
/// Builds a worker process definition.
pub fn worker_process(
  name : String,
  command : String,
  concurrency : Int,
  queues : Array[String],
  env_keys : Array[String],
) -> ProcessDefinition {
  process_definition(name, WorkerRole, command, concurrency, queues, env_keys)
}

///|
/// Builds a cable process definition.
pub fn cable_process(
  name : String,
  command : String,
  concurrency : Int,
  env_keys : Array[String],
) -> ProcessDefinition {
  process_definition(name, CableRole, command, concurrency, [], env_keys)
}

///|
/// Builds a release process definition.
pub fn release_process(
  name : String,
  command : String,
  env_keys : Array[String],
) -> ProcessDefinition {
  process_definition(name, ReleaseRole, command, 1, [], env_keys)
}

///|
/// Builds a scheduler process definition.
pub fn scheduler_process(
  name : String,
  command : String,
  env_keys : Array[String],
) -> ProcessDefinition {
  process_definition(name, SchedulerRole, command, 1, [], env_keys)
}

///|
/// Renders a Procfile-like process list.
pub fn process_summary(processes : Array[ProcessDefinition]) -> String {
  let lines : Array[String] = []
  for process in processes {
    let queues = if process.queues.is_empty() {
      ""
    } else {
      " queues=" + process.queues.join(",")
    }
    lines.push(
      process.name +
      " role=" +
      render_role(process.role) +
      " x" +
      process.concurrency.to_string() +
      queues +
      " cmd=" +
      process.command,
    )
  }
  lines.join("\n")
}

///|
/// Renders a release task plan.
pub fn release_summary(tasks : Array[ReleaseTask]) -> String {
  let lines : Array[String] = []
  for task in tasks {
    lines.push(
      task.name +
      " required=" +
      task.required.to_string() +
      " cmd=" +
      task.command,
    )
  }
  lines.join("\n")
}

///|
/// Renders one environment key list for diagnostics.
pub fn env_keys_summary(process : ProcessDefinition) -> String {
  process.name + " env=[" + process.env_keys.join(", ") + "]"
}

///|
/// Renders one process role into a lowercase token.
fn render_role(role : ProcessRole) -> String {
  match role {
    WebRole => "web"
    WorkerRole => "worker"
    CableRole => "cable"
    SchedulerRole => "scheduler"
    ReleaseRole => "release"
  }
}
