///|
/// Names one fixture row and the record it should load.
pub struct FixtureRow {
  name : String
  record : @orm.Record
}

///|
/// Groups fixture rows for one table.
pub struct FixtureSet {
  name : String
  table : String
  rows : Array[FixtureRow]
}

///|
/// Describes one `db:seed` style plan.
pub struct SeedPlan {
  name : String
  records : Array[@orm.Record]
  jobs : Array[@job.EnqueuedJob]
}

///|
/// Builds one named fixture row.
pub fn fixture_row(name : String, record : @orm.Record) -> FixtureRow {
  { name, record }
}

///|
/// Builds one fixture set.
pub fn fixture_set(
  name : String,
  table : String,
  rows : Array[FixtureRow],
) -> FixtureSet {
  { name, table, rows }
}

///|
/// Builds one seed plan.
pub fn seed_plan(
  name : String,
  records : Array[@orm.Record],
  jobs : Array[@job.EnqueuedJob],
) -> SeedPlan {
  { name, records, jobs }
}
