///|
/// Lists the migration operations supported by the framework.
pub enum MigrationStep {
  CreateTable(@orm.ModelSchema)
  AddColumn(String, @orm.Column)
  AddReference(String, String, String, Bool, Bool, String?)
  AddTimestamps(String, Bool)
  AddIndex(String, String, Bool)
  AddIndexConcurrently(String, String, Bool)
  RemoveIndex(String, String, Bool)
  RemoveIndexConcurrently(String, String, Bool)
  RemoveColumn(String, String)
  RenameColumn(String, String, String)
  ChangeColumnDefault(String, String, String?, String?)
  ChangeColumnNull(String, String, Bool, String?)
  RenameTable(String, String)
  DropTable(String)
  ExecuteSql(String)
  Reversible(String, String)
}

///|
/// Classifies one migration or step as safe, review-needed, or dangerous.
pub enum MigrationSafetyLevel {
  Safe
  Review
  Dangerous
} derive(Eq, Show)

///|
/// Describes one migration safety warning or error.
pub struct MigrationSafetyIssue {
  step_index : Int
  level : MigrationSafetyLevel
  title : String
  detail : String
  guidance : String
}

///|
/// Represents one ordered migration.
pub struct Migration {
  version : String
  name : String
  steps : Array[MigrationStep]
}

///|
/// Builds a migration from version, name, and steps.
pub fn migration(
  version : String,
  name : String,
  steps : Array[MigrationStep],
) -> Migration {
  { version, name, steps }
}

///|
/// Builds an empty migration that can be filled with chainable step builders.
pub fn migration_plan(version : String, name : String) -> Migration {
  { version, name, steps: [] }
}

///|
/// Builds one safety issue value.
pub fn migration_safety_issue(
  step_index : Int,
  level : MigrationSafetyLevel,
  title : String,
  detail : String,
  guidance : String,
) -> MigrationSafetyIssue {
  { step_index, level, title, detail, guidance }
}

///|
/// Adds one step to a migration.
pub fn Migration::with_step(
  self : Migration,
  step : MigrationStep,
) -> Migration {
  { ..self, steps: append_step(self.steps, step) }
}

///|
/// Adds a `CREATE TABLE` step to a migration.
pub fn Migration::create_table(
  self : Migration,
  model : @orm.ModelSchema,
) -> Migration {
  self.with_step(create_table_step(model))
}

///|
/// Adds an `ADD COLUMN` step to a migration.
pub fn Migration::add_column(
  self : Migration,
  table_name : String,
  column : @orm.Column,
) -> Migration {
  self.with_step(add_column_step(table_name, column))
}

///|
/// Adds an opinionated `add_reference` step to a migration.
pub fn Migration::add_reference(
  self : Migration,
  table_name : String,
  column_name : String,
  target_table : String,
  nullable? : Bool = false,
  unique? : Bool = false,
  default_value? : String? = None,
) -> Migration {
  self.with_step(
    add_reference_step(
      table_name~,
      column_name~,
      target_table~,
      nullable~,
      unique~,
      default_value~,
    ),
  )
}

///|
/// Adds timestamp columns to an existing table.
pub fn Migration::add_timestamps(
  self : Migration,
  table_name : String,
  nullable? : Bool = true,
) -> Migration {
  self.with_step(add_timestamps_step(table_name, nullable~))
}

///|
/// Adds an index creation step to a migration.
pub fn Migration::add_index(
  self : Migration,
  table_name : String,
  column_name : String,
  unique : Bool,
) -> Migration {
  self.with_step(add_index_step(table_name, column_name, unique))
}

///|
/// Adds a concurrent index creation step to a migration.
pub fn Migration::add_index_concurrently(
  self : Migration,
  table_name : String,
  column_name : String,
  unique : Bool,
) -> Migration {
  self.with_step(add_index_concurrently_step(table_name, column_name, unique))
}

///|
/// Adds an index removal step to a migration.
pub fn Migration::remove_index(
  self : Migration,
  table_name : String,
  column_name : String,
  unique? : Bool = false,
) -> Migration {
  self.with_step(remove_index_step(table_name, column_name, unique~))
}

///|
/// Adds a concurrent index removal step to a migration.
pub fn Migration::remove_index_concurrently(
  self : Migration,
  table_name : String,
  column_name : String,
  unique? : Bool = false,
) -> Migration {
  self.with_step(
    remove_index_concurrently_step(table_name, column_name, unique~),
  )
}

///|
/// Adds a `DROP COLUMN` step to a migration.
pub fn Migration::remove_column(
  self : Migration,
  table_name : String,
  column_name : String,
) -> Migration {
  self.with_step(remove_column_step(table_name, column_name))
}

///|
/// Adds a column rename step to a migration.
pub fn Migration::rename_column(
  self : Migration,
  table_name : String,
  from_ : String,
  to_ : String,
) -> Migration {
  self.with_step(rename_column_step(table_name, from_, to_))
}

///|
/// Adds a default-change step to a migration.
pub fn Migration::change_default(
  self : Migration,
  table_name : String,
  column_name : String,
  from_default : String?,
  to_default : String?,
) -> Migration {
  self.with_step(
    change_default_step(table_name, column_name, from_default, to_default),
  )
}

///|
/// Adds a nullability-change step to a migration.
pub fn Migration::change_null(
  self : Migration,
  table_name : String,
  column_name : String,
  nullable : Bool,
  backfill_value? : String? = None,
) -> Migration {
  self.with_step(
    change_null_step(table_name, column_name, nullable, backfill_value~),
  )
}

///|
/// Adds a table rename step to a migration.
pub fn Migration::rename_table(
  self : Migration,
  from_ : String,
  to_ : String,
) -> Migration {
  self.with_step(rename_table_step(from_, to_))
}

///|
/// Adds a `DROP TABLE` step to a migration.
pub fn Migration::drop_table(
  self : Migration,
  table_name : String,
) -> Migration {
  self.with_step(drop_table_step(table_name))
}

///|
/// Adds a raw SQL step to a migration.
pub fn Migration::execute_sql(self : Migration, sql : String) -> Migration {
  self.with_step(execute_sql_step(sql))
}

///|
/// Adds an explicit reversible SQL step to a migration.
pub fn Migration::reversible(
  self : Migration,
  up : String,
  down : String,
) -> Migration {
  self.with_step(reversible_step(up, down))
}

///|
/// Builds an `ADD COLUMN` migration step.
pub fn add_column_step(
  table_name : String,
  column : @orm.Column,
) -> MigrationStep {
  AddColumn(table_name, column)
}

///|
/// Builds an opinionated `add_reference` migration step.
#label_migration(table_name, allow_positional=true)
#label_migration(column_name, allow_positional=true)
#label_migration(target_table, allow_positional=true)
pub fn add_reference_step(
  table_name~ : String,
  column_name~ : String,
  target_table~ : String,
  nullable? : Bool = false,
  unique? : Bool = false,
  default_value? : String? = None,
) -> MigrationStep {
  AddReference(
    table_name, column_name, target_table, nullable, unique, default_value,
  )
}

///|
/// Builds a `CREATE TABLE` migration step from a model schema.
pub fn create_table_step(model : @orm.ModelSchema) -> MigrationStep {
  CreateTable(model)
}

///|
/// Builds a `DROP TABLE` migration step.
pub fn drop_table_step(table_name : String) -> MigrationStep {
  DropTable(table_name)
}

///|
/// Builds an explicit index creation step.
pub fn add_index_step(
  table_name : String,
  column_name : String,
  unique : Bool,
) -> MigrationStep {
  AddIndex(table_name, column_name, unique)
}

///|
/// Builds a concurrent index creation step.
pub fn add_index_concurrently_step(
  table_name : String,
  column_name : String,
  unique : Bool,
) -> MigrationStep {
  AddIndexConcurrently(table_name, column_name, unique)
}

///|
/// Builds an index removal step.
pub fn remove_index_step(
  table_name : String,
  column_name : String,
  unique? : Bool = false,
) -> MigrationStep {
  RemoveIndex(table_name, column_name, unique)
}

///|
/// Builds a concurrent index removal step.
pub fn remove_index_concurrently_step(
  table_name : String,
  column_name : String,
  unique? : Bool = false,
) -> MigrationStep {
  RemoveIndexConcurrently(table_name, column_name, unique)
}

///|
/// Builds a `DROP COLUMN` migration step.
pub fn remove_column_step(
  table_name : String,
  column_name : String,
) -> MigrationStep {
  RemoveColumn(table_name, column_name)
}

///|
/// Builds a column rename step.
pub fn rename_column_step(
  table_name : String,
  from_ : String,
  to_ : String,
) -> MigrationStep {
  RenameColumn(table_name, from_, to_)
}

///|
/// Builds a table rename step.
pub fn rename_table_step(from_ : String, to_ : String) -> MigrationStep {
  RenameTable(from_, to_)
}

///|
/// Builds a default-change step.
pub fn change_default_step(
  table_name : String,
  column_name : String,
  from_default : String?,
  to_default : String?,
) -> MigrationStep {
  ChangeColumnDefault(table_name, column_name, from_default, to_default)
}

///|
/// Builds a nullability-change step.
pub fn change_null_step(
  table_name : String,
  column_name : String,
  nullable : Bool,
  backfill_value? : String? = None,
) -> MigrationStep {
  ChangeColumnNull(table_name, column_name, nullable, backfill_value)
}

///|
/// Builds a timestamp-addition step.
pub fn add_timestamps_step(
  table_name : String,
  nullable? : Bool = true,
) -> MigrationStep {
  AddTimestamps(table_name, nullable)
}

///|
/// Builds a raw SQL migration step.
pub fn execute_sql_step(sql : String) -> MigrationStep {
  ExecuteSql(sql)
}

///|
/// Builds a migration step with separate up/down SQL.
pub fn reversible_step(up : String, down : String) -> MigrationStep {
  Reversible(up, down)
}

///|
/// Builds a simple create-table migration from a model schema.
pub fn migration_from_model(
  version : String,
  name : String,
  model : @orm.ModelSchema,
) -> Migration {
  { version, name, steps: [CreateTable(model)] }
}

///|
/// Renders the SQL needed to apply a migration.
pub fn migration_up_sql(migration : Migration) -> Array[String] {
  let statements : Array[String] = []
  for step in migration.steps {
    for statement in step_up_sql(step) {
      statements.push(statement)
    }
  }
  statements
}

///|
/// Renders the SQL needed to roll back a migration.
pub fn migration_down_sql(migration : Migration) -> Array[String] {
  let statements : Array[String] = []
  let reversed : Array[MigrationStep] = []
  for step in migration.steps {
    reversed.push(step)
  }
  let mut index = reversed.length() - 1
  while index >= 0 && reversed.length() > 0 {
    for statement in step_down_sql(reversed[index]) {
      statements.push(statement)
    }
    if index == 0 {
      break
    }
    index -= 1
  }
  statements
}

///|
/// Returns the same SQL as `migration_up_sql`.
pub fn migration_sql(migration : Migration) -> Array[String] {
  migration_up_sql(migration)
}

///|
/// Renders the SQL for a list of migrations in order.
pub fn schema_sql(migrations : Array[Migration]) -> Array[String] {
  let statements : Array[String] = []
  for migration in migrations {
    for statement in migration_up_sql(migration) {
      statements.push(statement)
    }
  }
  statements
}

///|
/// Analyzes a migration for production-safety issues.
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
/// Returns whether a migration has no flagged safety issues.
pub fn migration_safe(migration : Migration) -> Bool {
  analyze_migration(migration).is_empty()
}

///|
/// Returns the highest safety level found in a migration.
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
/// Renders a Strong-Migrations-style summary for one migration.
pub fn migration_safety_summary(migration : Migration) -> String {
  let issues = analyze_migration(migration)
  let lines : Array[String] = []
  lines.push(
    migration.name +
    " [" +
    render_safety_level(migration_risk_level(migration)) +
    "]",
  )
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
/// Renders the up-SQL for one migration step.
fn step_up_sql(step : MigrationStep) -> Array[String] {
  match step {
    CreateTable(model) => {
      let statements = [@orm.create_table_sql(model)]
      for index_sql in @orm.index_statements(model) {
        statements.push(index_sql)
      }
      statements
    }
    AddColumn(table_name, column) =>
      [
        "ALTER TABLE " +
        table_name +
        " ADD COLUMN " +
        @orm.column_definition_sql(column),
      ]
    AddReference(
      table_name,
      column_name,
      target_table,
      nullable,
      unique,
      default_value
    ) => {
      let column = reference_column(
        column_name, target_table, nullable, unique, default_value,
      )
      [
        "ALTER TABLE " +
        table_name +
        " ADD COLUMN " +
        @orm.column_definition_sql(column),
        index_statement(table_name, column_name, unique, false),
      ]
    }
    AddTimestamps(table_name, nullable) => {
      let null_sql = if nullable { "NULL" } else { "NOT NULL" }
      [
        "ALTER TABLE " +
        table_name +
        " ADD COLUMN created_at TIMESTAMP " +
        null_sql,
        "ALTER TABLE " +
        table_name +
        " ADD COLUMN updated_at TIMESTAMP " +
        null_sql,
      ]
    }
    AddIndex(table_name, column_name, unique) =>
      [index_statement(table_name, column_name, unique, false)]
    AddIndexConcurrently(table_name, column_name, unique) =>
      [index_statement(table_name, column_name, unique, true)]
    RemoveIndex(table_name, column_name, _) =>
      [drop_index_statement(table_name, column_name, false)]
    RemoveIndexConcurrently(table_name, column_name, _) =>
      [drop_index_statement(table_name, column_name, true)]
    RemoveColumn(table_name, column_name) =>
      ["ALTER TABLE " + table_name + " DROP COLUMN " + column_name]
    RenameColumn(table_name, from_, to_) =>
      ["ALTER TABLE " + table_name + " RENAME COLUMN " + from_ + " TO " + to_]
    ChangeColumnDefault(table_name, column_name, _, to_default) =>
      [change_default_sql(table_name, column_name, to_default)]
    ChangeColumnNull(table_name, column_name, nullable, backfill_value) =>
      change_null_up_sql(table_name, column_name, nullable, backfill_value)
    RenameTable(from_, to_) => ["ALTER TABLE " + from_ + " RENAME TO " + to_]
    DropTable(table_name) => ["DROP TABLE " + table_name]
    ExecuteSql(sql) => [sql]
    Reversible(up, _) => [up]
  }
}

///|
/// Renders the down-SQL for one migration step.
fn step_down_sql(step : MigrationStep) -> Array[String] {
  match step {
    CreateTable(model) => {
      let statements : Array[String] = []
      for column in model.columns {
        if column.indexed || column.unique {
          statements.push("DROP INDEX " + index_name(model.table, column.name))
        }
      }
      statements.push("DROP TABLE " + model.table)
      statements
    }
    AddColumn(table_name, column) =>
      ["ALTER TABLE " + table_name + " DROP COLUMN " + column.name]
    AddReference(table_name, column_name, _, _, _, _) =>
      [
        drop_index_statement(table_name, column_name, false),
        "ALTER TABLE " + table_name + " DROP COLUMN " + column_name,
      ]
    AddTimestamps(table_name, _) =>
      [
        "ALTER TABLE " + table_name + " DROP COLUMN updated_at",
        "ALTER TABLE " + table_name + " DROP COLUMN created_at",
      ]
    AddIndex(table_name, column_name, _) =>
      [drop_index_statement(table_name, column_name, false)]
    AddIndexConcurrently(table_name, column_name, _) =>
      [drop_index_statement(table_name, column_name, true)]
    RemoveIndex(table_name, column_name, unique) =>
      [index_statement(table_name, column_name, unique, false)]
    RemoveIndexConcurrently(table_name, column_name, unique) =>
      [index_statement(table_name, column_name, unique, true)]
    RemoveColumn(_, _) => ["-- manual down migration required"]
    RenameColumn(table_name, from_, to_) =>
      ["ALTER TABLE " + table_name + " RENAME COLUMN " + to_ + " TO " + from_]
    ChangeColumnDefault(table_name, column_name, from_default, _) =>
      [change_default_sql(table_name, column_name, from_default)]
    ChangeColumnNull(table_name, column_name, nullable, _) =>
      change_null_down_sql(table_name, column_name, nullable)
    RenameTable(from_, to_) => ["ALTER TABLE " + to_ + " RENAME TO " + from_]
    DropTable(table_name) =>
      ["-- table " + table_name + " cannot be restored automatically"]
    ExecuteSql(_) => ["-- manual rollback required"]
    Reversible(_, down) => [down]
  }
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
        [
          migration_safety_issue(
            step_index,
            Review,
            "add_reference without a phased backfill",
            "Adding `" +
            column_name +
            "` to `" +
            table_name +
            "` as NOT NULL can fail or lock existing rows.",
            "Prefer `add_reference(..., nullable=true)`, backfill the relationship, then `change_null_step(\"" +
            table_name +
            "\", \"" +
            column_name +
            "\", false, ...)`.",
          ),
        ]
      }
    AddTimestamps(table_name, nullable) =>
      if nullable {
        []
      } else {
        [
          migration_safety_issue(
            step_index,
            Review,
            "add_timestamps as NOT NULL",
            "Adding required timestamps to `" +
            table_name +
            "` can force a full-table rewrite.",
            "Prefer `add_timestamps_step(\"" +
            table_name +
            "\", nullable=true)` and tighten nullability after backfilling.",
          ),
        ]
      }
    AddIndex(table_name, column_name, _) =>
      [
        migration_safety_issue(
          step_index,
          Review,
          "non-concurrent index creation",
          "Creating an index on `" +
          table_name +
          "." +
          column_name +
          "` without a concurrent strategy can block writes.",
          "Prefer `add_index_concurrently_step(\"" +
          table_name +
          "\", \"" +
          column_name +
          "\", ...)` in production-style flows.",
        ),
      ]
    AddIndexConcurrently(_, _, _) => []
    RemoveIndex(table_name, column_name, _) =>
      [
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
        ),
      ]
    RemoveIndexConcurrently(_, _, _) => []
    RemoveColumn(table_name, column_name) =>
      [
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
        ),
      ]
    RenameColumn(table_name, from_, to_) =>
      [
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
        ),
      ]
    ChangeColumnDefault(_, _, _, _) => []
    ChangeColumnNull(table_name, column_name, nullable, backfill_value) =>
      if nullable || backfill_value is Some(_) {
        []
      } else {
        [
          migration_safety_issue(
            step_index,
            Review,
            "tightening nullability without a backfill",
            "Setting `" +
            table_name +
            "." +
            column_name +
            "` to NOT NULL without filling existing NULL rows can fail mid-deploy.",
            "Pass `backfill_value=Some(...)` or run an explicit backfill before `change_null_step(..., false)`.",
          ),
        ]
      }
    RenameTable(from_, to_) =>
      [
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
        ),
      ]
    DropTable(table_name) =>
      [
        migration_safety_issue(
          step_index,
          Dangerous,
          "destructive table drop",
          "Dropping `" +
          table_name +
          "` permanently removes the dataset and can break rollbacks.",
          "Decommission the table in phases and only drop it after code and data dependencies are gone.",
        ),
      ]
    ExecuteSql(_) =>
      [
        migration_safety_issue(
          step_index,
          Review,
          "raw SQL requires manual review",
          "Raw SQL bypasses the framework's migration safety conventions.",
          "Double-check locking, backfill, and rollback behavior manually for this step.",
        ),
      ]
    Reversible(_, _) =>
      [
        migration_safety_issue(
          step_index,
          Review,
          "manual reversible SQL requires review",
          "Custom reversible SQL is flexible but skips the typed schema helpers.",
          "Use typed steps when possible, or document why the raw SQL is safe.",
        ),
      ]
    CreateTable(_) => []
  }
}

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
fn reference_column(
  column_name : String,
  target_table : String,
  nullable : Bool,
  unique : Bool,
  default_value : String?,
) -> @orm.Column {
  let mut column = @orm.references_column(column_name, target_table)
  if nullable {
    column = @orm.nullable(column)
  }
  if unique {
    column = @orm.unique(column)
  }
  match default_value {
    Some(value) => @orm.with_default(column, value)
    None => column
  }
}

///|
fn index_statement(
  table_name : String,
  column_name : String,
  unique : Bool,
  concurrently : Bool,
) -> String {
  let unique_prefix = if unique { "UNIQUE " } else { "" }
  let concurrently_suffix = if concurrently { " CONCURRENTLY" } else { "" }
  "CREATE " +
  unique_prefix +
  "INDEX" +
  concurrently_suffix +
  " " +
  index_name(table_name, column_name) +
  " ON " +
  table_name +
  " (" +
  column_name +
  ")"
}

///|
fn drop_index_statement(
  table_name : String,
  column_name : String,
  concurrently : Bool,
) -> String {
  let concurrently_suffix = if concurrently { " CONCURRENTLY" } else { "" }
  "DROP INDEX" + concurrently_suffix + " " + index_name(table_name, column_name)
}

///|
fn index_name(table_name : String, column_name : String) -> String {
  "idx_" + table_name + "_" + column_name
}

///|
fn change_default_sql(
  table_name : String,
  column_name : String,
  default_value : String?,
) -> String {
  match default_value {
    Some(value) =>
      "ALTER TABLE " +
      table_name +
      " ALTER COLUMN " +
      column_name +
      " SET DEFAULT " +
      sql_literal(value)
    None =>
      "ALTER TABLE " +
      table_name +
      " ALTER COLUMN " +
      column_name +
      " DROP DEFAULT"
  }
}

///|
fn change_null_up_sql(
  table_name : String,
  column_name : String,
  nullable : Bool,
  backfill_value : String?,
) -> Array[String] {
  if nullable {
    [
      "ALTER TABLE " +
      table_name +
      " ALTER COLUMN " +
      column_name +
      " DROP NOT NULL",
    ]
  } else {
    let statements : Array[String] = []
    match backfill_value {
      Some(value) =>
        statements.push(
          "UPDATE " +
          table_name +
          " SET " +
          column_name +
          " = " +
          sql_literal(value) +
          " WHERE " +
          column_name +
          " IS NULL",
        )
      None => ()
    }
    statements.push(
      "ALTER TABLE " +
      table_name +
      " ALTER COLUMN " +
      column_name +
      " SET NOT NULL",
    )
    statements
  }
}

///|
fn change_null_down_sql(
  table_name : String,
  column_name : String,
  nullable : Bool,
) -> Array[String] {
  if nullable {
    [
      "ALTER TABLE " +
      table_name +
      " ALTER COLUMN " +
      column_name +
      " SET NOT NULL",
    ]
  } else {
    [
      "ALTER TABLE " +
      table_name +
      " ALTER COLUMN " +
      column_name +
      " DROP NOT NULL",
    ]
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
fn append_step(
  steps : Array[MigrationStep],
  step : MigrationStep,
) -> Array[MigrationStep] {
  let appended : Array[MigrationStep] = []
  for current in steps {
    appended.push(current)
  }
  appended.push(step)
  appended
}

///|
fn sql_literal(value : String) -> String {
  "'" + value.replace_all(old="'", new="''") + "'"
}
