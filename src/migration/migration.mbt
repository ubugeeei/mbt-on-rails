///|
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
  AddCheckConstraint(String, String, String, Bool)
  ValidateCheckConstraint(String, String)
  RemoveCheckConstraint(String, String, String?, Bool)
  AddForeignKey(String, String, String, Bool, String?)
  ValidateForeignKey(String, String, String)
  RemoveForeignKey(String, String, String, Bool, String?)
  ExecuteSql(String)
  Reversible(String, String)
}

///|
pub enum MigrationSafetyLevel {
  Safe
  Review
  Dangerous
} derive(Eq, Show)

///|
pub struct MigrationSafetyIssue {
  step_index : Int
  level : MigrationSafetyLevel
  title : String
  detail : String
  guidance : String
}

///|
pub struct Migration {
  version : String
  name : String
  steps : Array[MigrationStep]
}

///|
pub fn migration(
  version : String,
  name : String,
  steps : Array[MigrationStep],
) -> Migration {
  { version, name, steps }
}

///|
pub fn migration_plan(version : String, name : String) -> Migration {
  { version, name, steps: [] }
}

///|
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
pub fn Migration::with_step(
  self : Migration,
  step : MigrationStep,
) -> Migration {
  { ..self, steps: append_step(self.steps, step) }
}

///|
pub fn Migration::create_table(
  self : Migration,
  model : @orm.ModelSchema,
) -> Migration {
  self.with_step(create_table_step(model))
}

///|
pub fn Migration::add_column(
  self : Migration,
  table_name : String,
  column : @orm.Column,
) -> Migration {
  self.with_step(add_column_step(table_name, column))
}

///|
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
pub fn Migration::add_timestamps(
  self : Migration,
  table_name : String,
  nullable? : Bool = true,
) -> Migration {
  self.with_step(add_timestamps_step(table_name, nullable~))
}

///|
pub fn Migration::add_index(
  self : Migration,
  table_name : String,
  column_name : String,
  unique : Bool,
) -> Migration {
  self.with_step(add_index_step(table_name, column_name, unique))
}

///|
pub fn Migration::add_index_concurrently(
  self : Migration,
  table_name : String,
  column_name : String,
  unique : Bool,
) -> Migration {
  self.with_step(add_index_concurrently_step(table_name, column_name, unique))
}

///|
pub fn Migration::remove_index(
  self : Migration,
  table_name : String,
  column_name : String,
  unique? : Bool = false,
) -> Migration {
  self.with_step(remove_index_step(table_name, column_name, unique~))
}

///|
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
pub fn Migration::remove_column(
  self : Migration,
  table_name : String,
  column_name : String,
) -> Migration {
  self.with_step(remove_column_step(table_name, column_name))
}

///|
pub fn Migration::rename_column(
  self : Migration,
  table_name : String,
  from_ : String,
  to_ : String,
) -> Migration {
  self.with_step(rename_column_step(table_name, from_, to_))
}

///|
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
pub fn Migration::rename_table(
  self : Migration,
  from_ : String,
  to_ : String,
) -> Migration {
  self.with_step(rename_table_step(from_, to_))
}

///|
pub fn Migration::drop_table(
  self : Migration,
  table_name : String,
) -> Migration {
  self.with_step(drop_table_step(table_name))
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
