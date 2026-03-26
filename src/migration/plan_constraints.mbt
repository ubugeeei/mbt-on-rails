///|
pub fn Migration::add_check_constraint(
  self : Migration,
  table_name : String,
  constraint_name : String,
  expression : String,
  validate? : Bool = true,
) -> Migration {
  self.with_step(
    add_check_constraint_step(
      table_name,
      constraint_name,
      expression,
      validate~,
    ),
  )
}

///|
pub fn Migration::validate_check_constraint(
  self : Migration,
  table_name : String,
  constraint_name : String,
) -> Migration {
  self.with_step(validate_check_constraint_step(table_name, constraint_name))
}

///|
pub fn Migration::remove_check_constraint(
  self : Migration,
  table_name : String,
  constraint_name : String,
  expression? : String? = None,
  validate? : Bool = true,
) -> Migration {
  self.with_step(
    remove_check_constraint_step(
      table_name,
      constraint_name,
      expression~,
      validate~,
    ),
  )
}

///|
pub fn Migration::add_foreign_key(
  self : Migration,
  table_name : String,
  column_name : String,
  target_table : String,
  validate? : Bool = true,
  on_delete? : String? = None,
) -> Migration {
  self.with_step(
    add_foreign_key_step(
      table_name,
      column_name,
      target_table,
      validate~,
      on_delete~,
    ),
  )
}

///|
pub fn Migration::validate_foreign_key(
  self : Migration,
  table_name : String,
  column_name : String,
  target_table : String,
) -> Migration {
  self.with_step(
    validate_foreign_key_step(table_name, column_name, target_table),
  )
}

///|
pub fn Migration::remove_foreign_key(
  self : Migration,
  table_name : String,
  column_name : String,
  target_table : String,
  validate? : Bool = true,
  on_delete? : String? = None,
) -> Migration {
  self.with_step(
    remove_foreign_key_step(
      table_name,
      column_name,
      target_table,
      validate~,
      on_delete~,
    ),
  )
}

///|
pub fn Migration::execute_sql(self : Migration, sql : String) -> Migration {
  self.with_step(execute_sql_step(sql))
}

///|
pub fn Migration::reversible(
  self : Migration,
  up : String,
  down : String,
) -> Migration {
  self.with_step(reversible_step(up, down))
}
