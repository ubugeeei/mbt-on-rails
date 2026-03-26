///|
/// Lists the deployable process roles supported by the framework.
pub enum ProcessRole {
  WebRole
  WorkerRole
  CableRole
  SchedulerRole
  ReleaseRole
} derive(Eq, Show)

///|
/// Describes one long-running process entry.
pub struct ProcessDefinition {
  name : String
  role : ProcessRole
  command : String
  concurrency : Int
  queues : Array[String]
  env_keys : Array[String]
}

///|
/// Describes one release-time task such as migrations.
pub struct ReleaseTask {
  name : String
  command : String
  required : Bool
}

///|
/// Builds one process definition.
pub fn process_definition(
  name : String,
  role : ProcessRole,
  command : String,
  concurrency : Int,
  queues : Array[String],
  env_keys : Array[String],
) -> ProcessDefinition {
  { name, role, command, concurrency, queues, env_keys }
}

///|
/// Builds one release task.
#label_migration(name, allow_positional=true)
#label_migration(command, allow_positional=true)
#label_migration(required, allow_positional=true)
pub fn release_task(
  name~ : String,
  command~ : String,
  required~ : Bool,
) -> ReleaseTask {
  { name, command, required }
}
