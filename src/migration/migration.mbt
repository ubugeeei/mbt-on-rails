///|
/// Lists the migration operations supported by the framework.
pub enum MigrationStep {
  CreateTable(@orm.ModelSchema)
  AddColumn(String, @orm.Column)
  AddIndex(String, String, Bool)
  RemoveColumn(String, String)
  RenameTable(String, String)
  DropTable(String)
  ExecuteSql(String)
  Reversible(String, String)
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
/// Builds an `ADD COLUMN` migration step.
pub fn add_column_step(
  table_name : String,
  column : @orm.Column,
) -> MigrationStep {
  AddColumn(table_name, column)
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
/// Builds a `DROP COLUMN` migration step.
pub fn remove_column_step(
  table_name : String,
  column_name : String,
) -> MigrationStep {
  RemoveColumn(table_name, column_name)
}

///|
/// Builds a table rename step.
pub fn rename_table_step(from_ : String, to_ : String) -> MigrationStep {
  RenameTable(from_, to_)
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
    AddIndex(table_name, column_name, unique) => {
      let unique_prefix = if unique { "UNIQUE " } else { "" }
      let index_name = "idx_" + table_name + "_" + column_name
      [
        "CREATE " +
        unique_prefix +
        "INDEX " +
        index_name +
        " ON " +
        table_name +
        " (" +
        column_name +
        ")",
      ]
    }
    RemoveColumn(table_name, column_name) =>
      ["ALTER TABLE " + table_name + " DROP COLUMN " + column_name]
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
          statements.push("DROP INDEX idx_" + model.table + "_" + column.name)
        }
      }
      statements.push("DROP TABLE " + model.table)
      statements
    }
    AddColumn(table_name, column) =>
      ["ALTER TABLE " + table_name + " DROP COLUMN " + column.name]
    AddIndex(table_name, column_name, _) =>
      ["DROP INDEX idx_" + table_name + "_" + column_name]
    RemoveColumn(_, _) => ["-- manual down migration required"]
    RenameTable(from_, to_) => ["ALTER TABLE " + to_ + " RENAME TO " + from_]
    DropTable(table_name) =>
      ["-- table " + table_name + " cannot be restored automatically"]
    ExecuteSql(_) => ["-- manual rollback required"]
    Reversible(_, down) => [down]
  }
}
