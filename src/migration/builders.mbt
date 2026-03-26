///|
pub fn add_column_step(
  table_name : String,
  column : @orm.Column,
) -> MigrationStep {
  AddColumn(table_name, column)
}

///|
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
pub fn create_table_step(model : @orm.ModelSchema) -> MigrationStep {
  CreateTable(model)
}

///|
pub fn drop_table_step(table_name : String) -> MigrationStep {
  DropTable(table_name)
}

///|
pub fn add_index_step(
  table_name : String,
  column_name : String,
  unique : Bool,
) -> MigrationStep {
  AddIndex(table_name, column_name, unique)
}

///|
pub fn add_index_concurrently_step(
  table_name : String,
  column_name : String,
  unique : Bool,
) -> MigrationStep {
  AddIndexConcurrently(table_name, column_name, unique)
}

///|
pub fn remove_index_step(
  table_name : String,
  column_name : String,
  unique? : Bool = false,
) -> MigrationStep {
  RemoveIndex(table_name, column_name, unique)
}

///|
pub fn remove_index_concurrently_step(
  table_name : String,
  column_name : String,
  unique? : Bool = false,
) -> MigrationStep {
  RemoveIndexConcurrently(table_name, column_name, unique)
}

///|
pub fn remove_column_step(
  table_name : String,
  column_name : String,
) -> MigrationStep {
  RemoveColumn(table_name, column_name)
}

///|
pub fn rename_column_step(
  table_name : String,
  from_ : String,
  to_ : String,
) -> MigrationStep {
  RenameColumn(table_name, from_, to_)
}

///|
pub fn rename_table_step(from_ : String, to_ : String) -> MigrationStep {
  RenameTable(from_, to_)
}

///|
pub fn change_default_step(
  table_name : String,
  column_name : String,
  from_default : String?,
  to_default : String?,
) -> MigrationStep {
  ChangeColumnDefault(table_name, column_name, from_default, to_default)
}

///|
pub fn change_null_step(
  table_name : String,
  column_name : String,
  nullable : Bool,
  backfill_value? : String? = None,
) -> MigrationStep {
  ChangeColumnNull(table_name, column_name, nullable, backfill_value)
}

///|
pub fn add_timestamps_step(
  table_name : String,
  nullable? : Bool = true,
) -> MigrationStep {
  AddTimestamps(table_name, nullable)
}

///|
pub fn add_check_constraint_step(
  table_name : String,
  constraint_name : String,
  expression : String,
  validate? : Bool = true,
) -> MigrationStep {
  AddCheckConstraint(table_name, constraint_name, expression, validate)
}

///|
pub fn validate_check_constraint_step(
  table_name : String,
  constraint_name : String,
) -> MigrationStep {
  ValidateCheckConstraint(table_name, constraint_name)
}

///|
pub fn remove_check_constraint_step(
  table_name : String,
  constraint_name : String,
  expression? : String? = None,
  validate? : Bool = true,
) -> MigrationStep {
  RemoveCheckConstraint(table_name, constraint_name, expression, validate)
}

///|
pub fn add_foreign_key_step(
  table_name : String,
  column_name : String,
  target_table : String,
  validate? : Bool = true,
  on_delete? : String? = None,
) -> MigrationStep {
  AddForeignKey(table_name, column_name, target_table, validate, on_delete)
}

///|
pub fn validate_foreign_key_step(
  table_name : String,
  column_name : String,
  target_table : String,
) -> MigrationStep {
  ValidateForeignKey(table_name, column_name, target_table)
}

///|
pub fn remove_foreign_key_step(
  table_name : String,
  column_name : String,
  target_table : String,
  validate? : Bool = true,
  on_delete? : String? = None,
) -> MigrationStep {
  RemoveForeignKey(table_name, column_name, target_table, validate, on_delete)
}

///|
pub fn execute_sql_step(sql : String) -> MigrationStep {
  ExecuteSql(sql)
}

///|
pub fn reversible_step(up : String, down : String) -> MigrationStep {
  Reversible(up, down)
}

///|
pub fn migration_from_model(
  version : String,
  name : String,
  model : @orm.ModelSchema,
) -> Migration {
  { version, name, steps: [CreateTable(model)] }
}
