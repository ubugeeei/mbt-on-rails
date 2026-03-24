///|
/// Loads one fixture set into the in-memory database.
pub fn load_fixture_set(
  database : @orm.MemoryDatabase,
  fixtures : FixtureSet,
) -> @orm.MemoryDatabase {
  let mut current = database
  for row in fixtures.rows {
    current = @orm.insert_record(current, row.record)
  }
  current
}

///|
/// Loads many fixture sets into the in-memory database.
pub fn load_fixtures(
  database : @orm.MemoryDatabase,
  fixtures : Array[FixtureSet],
) -> @orm.MemoryDatabase {
  let mut current = database
  for fixture in fixtures {
    current = load_fixture_set(current, fixture)
  }
  current
}

///|
/// Applies one seed plan to the in-memory database.
pub fn apply_seed(
  database : @orm.MemoryDatabase,
  plan : SeedPlan,
) -> @orm.MemoryDatabase {
  let mut current = database
  for record in plan.records {
    current = @orm.insert_record(current, record)
  }
  current
}

///|
/// Renders one fixture set in a CLI-friendly format.
pub fn fixture_summary(fixtures : FixtureSet) -> String {
  let labels : Array[String] = []
  for row in fixtures.rows {
    labels.push(row.name)
  }
  "fixtures " +
  fixtures.name +
  " table=" +
  fixtures.table +
  " rows=[" +
  labels.join(", ") +
  "]"
}

///|
/// Renders one seed plan in a CLI-friendly format.
pub fn seed_summary(plan : SeedPlan) -> String {
  "seed " +
  plan.name +
  " records=" +
  plan.records.length().to_string() +
  " jobs=" +
  plan.jobs.length().to_string()
}
