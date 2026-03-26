///|
/// Re-exports in-memory relation execution helpers for the Active Record surface.
pub using @orm {
  type RelationExecutionIssue,
  type RelationExecutionOutcome,
  execute_relation,
  relation_execution_issue,
}
