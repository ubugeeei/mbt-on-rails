///|
fn add_column_issues(
  table_name : String,
  column : @orm.Column,
  step_index : Int,
) -> Array[MigrationSafetyIssue] {
  if column.nullable || column.default_value is Some(_) {
    []
  } else {
    [
      migration_safety_issue(
        step_index,
        Review,
        "add_column without a phased backfill",
        "Adding `" +
        column.name +
        "` to `" +
        table_name +
        "` as NOT NULL without a default is risky on existing rows.",
        "Prefer `nullable(column)` first, backfill values, then tighten nullability with `change_null_step(...)`.",
      ),
    ]
  }
}

///|
fn phased_reference_issue(
  step_index : Int,
  table_name : String,
  column_name : String,
) -> MigrationSafetyIssue {
  migration_safety_issue(
    step_index,
    Review,
    "add_reference without a phased backfill",
    "Adding `" +
    column_name +
    "` to `" +
    table_name +
    "` as NOT NULL can fail or lock existing rows.",
    "Prefer `add_reference(..., nullable=true)`, backfill the relationship, then `change_null_step(...)`.",
  )
}

///|
fn add_reference_issues(
  step_index : Int,
  table_name : String,
  column_name : String,
  target_table : String,
  nullable : Bool,
  default_value : String?,
) -> Array[MigrationSafetyIssue] {
  let issues : Array[MigrationSafetyIssue] = []
  if !nullable && default_value is None {
    issues.push(phased_reference_issue(step_index, table_name, column_name))
  }
  issues.push(blocking_index_issue(step_index, table_name, column_name))
  issues.push(
    inline_reference_foreign_key_issue(
      step_index, table_name, column_name, target_table,
    ),
  )
  issues
}

///|
fn inline_reference_foreign_key_issue(
  step_index : Int,
  table_name : String,
  column_name : String,
  target_table : String,
) -> MigrationSafetyIssue {
  migration_safety_issue(
    step_index,
    Review,
    "inline foreign key creation",
    "Adding `" +
    table_name +
    "." +
    column_name +
    "` with an inline `REFERENCES " +
    target_table +
    "(id)` constraint can validate existing rows and take locks during deploys.",
    "Prefer adding the column as nullable, backfilling it separately, then using `add_foreign_key(..., validate=false)` and `validate_foreign_key_step(...)`.",
  )
}

///|
fn non_nullable_timestamps_issue(
  step_index : Int,
  table_name : String,
) -> MigrationSafetyIssue {
  migration_safety_issue(
    step_index,
    Review,
    "add_timestamps as NOT NULL",
    "Adding required timestamps to `" +
    table_name +
    "` can force a full-table rewrite.",
    "Prefer `add_timestamps_step(..., nullable=true)` and tighten nullability after backfilling.",
  )
}

///|
fn blocking_index_issue(
  step_index : Int,
  table_name : String,
  column_name : String,
) -> MigrationSafetyIssue {
  migration_safety_issue(
    step_index,
    Review,
    "non-concurrent index creation",
    "Creating an index on `" +
    table_name +
    "." +
    column_name +
    "` without a concurrent strategy can block writes.",
    "Prefer `add_index_concurrently_step(...)` in production-style flows.",
  )
}

///|
fn blocking_drop_index_issue(
  step_index : Int,
  table_name : String,
  column_name : String,
) -> MigrationSafetyIssue {
  migration_safety_issue(
    step_index,
    Review,
    "non-concurrent index removal",
    "Dropping the index on `" +
    table_name +
    "." +
    column_name +
    "` can block traffic on production databases.",
    "Prefer `remove_index_concurrently_step(...)` when deploy safety matters.",
  )
}

///|
fn destructive_column_issue(
  step_index : Int,
  table_name : String,
  column_name : String,
) -> MigrationSafetyIssue {
  migration_safety_issue(
    step_index,
    Dangerous,
    "destructive column removal",
    "Dropping `" +
    table_name +
    "." +
    column_name +
    "` permanently removes data and can break old code paths during deploys.",
    "Split the change: stop writing/reading the column first, deploy, then remove it in a later migration.",
  )
}

///|
fn rename_column_issue(
  step_index : Int,
  table_name : String,
  from_ : String,
  to_ : String,
) -> MigrationSafetyIssue {
  migration_safety_issue(
    step_index,
    Review,
    "column rename across deploy boundaries",
    "Renaming `" +
    table_name +
    "." +
    from_ +
    "` to `" +
    to_ +
    "` can break running app versions that still reference the old name.",
    "Prefer add-copy-switch-remove or deploy app code in phases before the rename.",
  )
}

///|
fn tighten_null_issue(
  step_index : Int,
  table_name : String,
  column_name : String,
) -> MigrationSafetyIssue {
  migration_safety_issue(
    step_index,
    Review,
    "tightening nullability without a backfill",
    "Setting `" +
    table_name +
    "." +
    column_name +
    "` to NOT NULL without filling existing NULL rows can fail mid-deploy.",
    "Backfill existing NULL rows in a separate operational phase before scheduling the NOT NULL change.",
  )
}

///|
fn inline_backfill_tighten_null_issue(
  step_index : Int,
  table_name : String,
  column_name : String,
) -> MigrationSafetyIssue {
  migration_safety_issue(
    step_index,
    Review,
    "inline backfill before NOT NULL",
    "Updating `" +
    table_name +
    "." +
    column_name +
    "` inside the same migration before `SET NOT NULL` can lock or rewrite many rows.",
    "Backfill in small batches ahead of the migration, then tighten nullability in an isolated reviewed step.",
  )
}

///|
fn rename_table_issue(
  step_index : Int,
  from_ : String,
  to_ : String,
) -> MigrationSafetyIssue {
  migration_safety_issue(
    step_index,
    Review,
    "table rename across deploy boundaries",
    "Renaming `" +
    from_ +
    "` to `" +
    to_ +
    "` can break code still pointing at the old table name.",
    "Prefer dual-read/write phases or a compatibility view if this must happen online.",
  )
}

///|
fn drop_table_issue(
  step_index : Int,
  table_name : String,
) -> MigrationSafetyIssue {
  migration_safety_issue(
    step_index,
    Dangerous,
    "destructive table drop",
    "Dropping `" +
    table_name +
    "` permanently removes the dataset and can break rollbacks.",
    "Decommission the table in phases and only drop it after code and data dependencies are gone.",
  )
}

///|
fn validated_constraint_issue(
  step_index : Int,
  table_name : String,
  constraint_name : String,
  kind : String,
  safe_builder : String,
) -> MigrationSafetyIssue {
  migration_safety_issue(
    step_index,
    Review,
    "validated " + kind + " creation",
    "Adding `" +
    constraint_name +
    "` to `" +
    table_name +
    "` with immediate validation can scan the whole table during deploys.",
    "Prefer `" +
    safe_builder +
    "`, backfill invalid rows, then run the matching `validate_*` step.",
  )
}

///|
fn constraint_removal_issue(
  step_index : Int,
  table_name : String,
  constraint_name : String,
) -> MigrationSafetyIssue {
  migration_safety_issue(
    step_index,
    Review,
    "constraint removal requires review",
    "Dropping `" +
    constraint_name +
    "` from `" +
    table_name +
    "` loosens integrity guarantees and may hide invalid data during rolling deploys.",
    "Keep constraint removal isolated, and confirm the application no longer relies on database-enforced validation.",
  )
}
