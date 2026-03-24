///|
fn main {
  let processes = [
    @mbor.web_process("web", "moon run cmd/main", 2, ["PORT", "DATABASE_URL"]),
    @mbor.worker_process(
      "worker",
      "moon run examples/rails_ops",
      4,
      ["default", "mailers"],
      ["DATABASE_URL", "REDIS_URL"],
    ),
    @mbor.cable_process("cable", "moon run cmd/main", 1, ["REDIS_URL"]),
    @mbor.scheduler_process("scheduler", "moon run examples/production_stack", [
      "DATABASE_URL", "REDIS_URL",
    ]),
    @mbor.release_process("release", "moon run examples/orm_migration", [
      "DATABASE_URL",
    ]),
  ]
  let release = [
    @mbor.release_task("db:migrate", "moon run examples/orm_migration", true),
    @mbor.release_task("db:seed", "moon run examples/rails_ops", false),
  ]

  println("Process Topology Example")
  println("========================")
  println("")
  println("Processes")
  println(@mbor.process_summary(processes))
  println("")
  println("Release")
  println(@mbor.release_summary(release))
  println("")
  println("Env")
  println(@mbor.env_keys_summary(processes[0]))
}
