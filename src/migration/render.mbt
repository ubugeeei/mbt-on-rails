///|
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
pub fn migration_sql(migration : Migration) -> Array[String] {
  migration_up_sql(migration)
}

///|
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
fn step_up_sql(step : MigrationStep) -> Array[String] {
  match step {
    CreateTable(model) => create_table_statements(model)
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
    ) =>
      add_reference_statements(
        table_name, column_name, target_table, nullable, unique, default_value,
      )
    AddTimestamps(table_name, nullable) =>
      add_timestamps_statements(table_name, nullable)
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
    AddCheckConstraint(table_name, constraint_name, expression, validate) =>
      [
        check_constraint_statement(
          table_name, constraint_name, expression, validate,
        ),
      ]
    ValidateCheckConstraint(table_name, constraint_name) =>
      [validate_constraint_statement(table_name, constraint_name)]
    RemoveCheckConstraint(table_name, constraint_name, _, _) =>
      [drop_constraint_statement(table_name, constraint_name)]
    AddForeignKey(table_name, column_name, target_table, validate, on_delete) =>
      [
        foreign_key_constraint_statement(
          table_name, column_name, target_table, validate, on_delete,
        ),
      ]
    ValidateForeignKey(table_name, column_name, _) =>
      [
        validate_constraint_statement(
          table_name,
          foreign_key_constraint_name(table_name, column_name),
        ),
      ]
    RemoveForeignKey(table_name, column_name, _, _, _) =>
      [
        drop_constraint_statement(
          table_name,
          foreign_key_constraint_name(table_name, column_name),
        ),
      ]
    ExecuteSql(sql) => [sql]
    Reversible(up, _) => [up]
  }
}

///|
fn step_down_sql(step : MigrationStep) -> Array[String] {
  match step {
    CreateTable(model) => drop_created_table_statements(model)
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
    AddCheckConstraint(table_name, constraint_name, _, _) =>
      [drop_constraint_statement(table_name, constraint_name)]
    ValidateCheckConstraint(_, _) =>
      ["-- constraint validation state cannot be reversed automatically"]
    RemoveCheckConstraint(table_name, constraint_name, expression, validate) =>
      restore_check_constraint_statements(
        table_name, constraint_name, expression, validate,
      )
    AddForeignKey(table_name, column_name, _, _, _) =>
      [
        drop_constraint_statement(
          table_name,
          foreign_key_constraint_name(table_name, column_name),
        ),
      ]
    ValidateForeignKey(_, _, _) =>
      ["-- constraint validation state cannot be reversed automatically"]
    RemoveForeignKey(table_name, column_name, target_table, validate, on_delete) =>
      [
        foreign_key_constraint_statement(
          table_name, column_name, target_table, validate, on_delete,
        ),
      ]
    ExecuteSql(_) => ["-- manual rollback required"]
    Reversible(_, down) => [down]
  }
}
