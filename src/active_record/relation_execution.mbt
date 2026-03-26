///|
/// Describes one reason a relation cannot be executed in the in-memory adapter.
pub struct RelationExecutionIssue {
  feature : String
  detail : String
} derive(Eq, Show)

///|
/// Represents the result of executing one relation in memory.
pub enum RelationExecutionOutcome {
  ExecutedRecords(Array[Record])
  RelationExecutionFailed(Array[RelationExecutionIssue])
}

///|
pub fn relation_execution_issue(
  feature : String,
  detail : String,
) -> RelationExecutionIssue {
  { feature, detail }
}

///|
pub fn RelationExecutionIssue::message(self : RelationExecutionIssue) -> String {
  self.feature + ": " + self.detail
}

///|
pub fn execute_relation(
  schema : ModelSchema,
  db : MemoryDatabase,
  relation : Relation,
) -> RelationExecutionOutcome {
  if relation.none {
    return ExecutedRecords([])
  }
  let issues = relation_execution_issues(schema, relation)
  if not(issues.is_empty()) {
    return RelationExecutionFailed(issues)
  }
  ExecutedRecords(
    apply_relation_to_rows(
      schema,
      relation,
      relation_rows_for_table(db, relation.table),
    ),
  )
}

///|
pub fn MemoryDatabase::execute_relation(
  self : MemoryDatabase,
  schema : ModelSchema,
  relation : Relation,
) -> RelationExecutionOutcome {
  execute_relation(schema, self, relation)
}

///|
pub fn RelationExecutionOutcome::records(
  self : RelationExecutionOutcome,
) -> Array[Record] {
  match self {
    ExecutedRecords(records) => records
    RelationExecutionFailed(_) => []
  }
}

///|
pub fn RelationExecutionOutcome::issues(
  self : RelationExecutionOutcome,
) -> Array[RelationExecutionIssue] {
  match self {
    ExecutedRecords(_) => []
    RelationExecutionFailed(issues) => issues
  }
}

///|
pub fn RelationExecutionOutcome::first(
  self : RelationExecutionOutcome,
) -> Record? {
  let records = self.records()
  if records.is_empty() {
    None
  } else {
    Some(records[0])
  }
}

///|
pub fn RelationExecutionOutcome::count(self : RelationExecutionOutcome) -> Int {
  self.records().length()
}

///|
pub fn RelationExecutionOutcome::exists(
  self : RelationExecutionOutcome,
) -> Bool {
  self.count() > 0
}
