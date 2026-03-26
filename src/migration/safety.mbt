///|
pub fn analyze_migration(migration : Migration) -> Array[MigrationSafetyIssue] {
  let issues : Array[MigrationSafetyIssue] = []
  let mut step_index = 0
  for step in migration.steps {
    for issue in step_safety_issues(step, step_index) {
      issues.push(issue)
    }
    step_index += 1
  }
  issues
}

///|
pub fn migration_safe(migration : Migration) -> Bool {
  analyze_migration(migration).is_empty()
}

///|
pub fn migration_risk_level(migration : Migration) -> MigrationSafetyLevel {
  let issues = analyze_migration(migration)
  if issues.any(fn(issue) { issue.level == Dangerous }) {
    Dangerous
  } else if issues.any(fn(issue) { issue.level == Review }) {
    Review
  } else {
    Safe
  }
}

///|
pub fn migration_safety_summary(migration : Migration) -> String {
  let issues = analyze_migration(migration)
  let lines : Array[String] = [
    migration.name +
    " [" +
    render_safety_level(migration_risk_level(migration)) +
    "]",
  ]
  if issues.is_empty() {
    lines.push("  - no safety issues detected")
    return lines.join("\n")
  }
  for issue in issues {
    lines.push(
      "  - step " +
      (issue.step_index + 1).to_string() +
      " [" +
      render_safety_level(issue.level) +
      "] " +
      issue.title,
    )
    lines.push("    " + issue.detail)
    lines.push("    guidance: " + issue.guidance)
  }
  lines.join("\n")
}

///|
fn step_safety_issues(
  step : MigrationStep,
  step_index : Int,
) -> Array[MigrationSafetyIssue] {
  match step {
    AddColumn(table_name, column) =>
      add_column_issues(table_name, column, step_index)
    AddReference(table_name, column_name, _, nullable, _, default_value) =>
      if nullable || default_value is Some(_) {
        []
      } else {
        [phased_reference_issue(step_index, table_name, column_name)]
      }
    AddTimestamps(table_name, nullable) =>
      if nullable {
        []
      } else {
        [non_nullable_timestamps_issue(step_index, table_name)]
      }
    AddIndex(table_name, column_name, _) =>
      [blocking_index_issue(step_index, table_name, column_name)]
    AddIndexConcurrently(_, _, _) => []
    RemoveIndex(table_name, column_name, _) =>
      [blocking_drop_index_issue(step_index, table_name, column_name)]
    RemoveIndexConcurrently(_, _, _) => []
    RemoveColumn(table_name, column_name) =>
      [destructive_column_issue(step_index, table_name, column_name)]
    RenameColumn(table_name, from_, to_) =>
      [rename_column_issue(step_index, table_name, from_, to_)]
    ChangeColumnDefault(_, _, _, _) => []
    ChangeColumnNull(table_name, column_name, nullable, backfill_value) =>
      if nullable || backfill_value is Some(_) {
        []
      } else {
        [tighten_null_issue(step_index, table_name, column_name)]
      }
    RenameTable(from_, to_) => [rename_table_issue(step_index, from_, to_)]
    DropTable(table_name) => [drop_table_issue(step_index, table_name)]
    AddCheckConstraint(table_name, constraint_name, _, validate) =>
      if validate {
        [
          validated_constraint_issue(
            step_index, table_name, constraint_name, "check constraint", "add_check_constraint(..., validate=false)",
          ),
        ]
      } else {
        []
      }
    ValidateCheckConstraint(_, _) => []
    RemoveCheckConstraint(table_name, constraint_name, _, _) =>
      [constraint_removal_issue(step_index, table_name, constraint_name)]
    AddForeignKey(table_name, column_name, _, validate, _) =>
      if validate {
        [
          validated_constraint_issue(
            step_index, table_name, column_name, "foreign key", "add_foreign_key(..., validate=false)",
          ),
        ]
      } else {
        []
      }
    ValidateForeignKey(_, _, _) => []
    RemoveForeignKey(table_name, column_name, _, _, _) =>
      [
        constraint_removal_issue(
          step_index,
          table_name,
          foreign_key_constraint_name(table_name, column_name),
        ),
      ]
    ExecuteSql(_) => [raw_sql_issue(step_index)]
    Reversible(_, _) => [manual_reversible_issue(step_index)]
    CreateTable(_) => []
  }
}

///|
fn render_safety_level(level : MigrationSafetyLevel) -> String {
  match level {
    Safe => "safe"
    Review => "review"
    Dangerous => "dangerous"
  }
}

///|
fn raw_sql_issue(step_index : Int) -> MigrationSafetyIssue {
  migration_safety_issue(
    step_index,
    Review,
    "raw SQL requires manual review",
    "Raw SQL bypasses the framework's migration safety conventions.",
    "Double-check locking, backfill, and rollback behavior manually for this step.",
  )
}

///|
fn manual_reversible_issue(step_index : Int) -> MigrationSafetyIssue {
  migration_safety_issue(
    step_index,
    Review,
    "manual reversible SQL requires review",
    "Custom reversible SQL is flexible but skips the typed schema helpers.",
    "Use typed steps when possible, or document why the raw SQL is safe.",
  )
}
