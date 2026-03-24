///|
test "process topology example summaries stay stable" {
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
  ]
  let release = [
    @mbor.release_task("db:migrate", "moon run examples/orm_migration", true),
    @mbor.release_task("db:seed", "moon run examples/rails_ops", false),
  ]

  assert_true(@mbor.process_summary(processes).contains("worker role=worker"))
  assert_true(@mbor.env_keys_summary(processes[0]).contains("DATABASE_URL"))
  assert_true(@mbor.release_summary(release).contains("db:migrate"))
}

///|
test "process topology main smoke stays runnable" {
  run_example()
  assert_true(true)
}
