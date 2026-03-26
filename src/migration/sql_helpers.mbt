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
fn check_constraint_statement(
  table_name : String,
  constraint_name : String,
  expression : String,
  validate : Bool,
) -> String {
  let validation_suffix = if validate { "" } else { " NOT VALID" }
  "ALTER TABLE " +
  table_name +
  " ADD CONSTRAINT " +
  constraint_name +
  " CHECK (" +
  expression +
  ")" +
  validation_suffix
}

///|
fn validate_constraint_statement(
  table_name : String,
  constraint_name : String,
) -> String {
  "ALTER TABLE " + table_name + " VALIDATE CONSTRAINT " + constraint_name
}

///|
fn drop_constraint_statement(
  table_name : String,
  constraint_name : String,
) -> String {
  "ALTER TABLE " + table_name + " DROP CONSTRAINT " + constraint_name
}

///|
fn foreign_key_constraint_statement(
  table_name : String,
  column_name : String,
  target_table : String,
  validate : Bool,
  on_delete : String?,
) -> String {
  let validation_suffix = if validate { "" } else { " NOT VALID" }
  "ALTER TABLE " +
  table_name +
  " ADD CONSTRAINT " +
  foreign_key_constraint_name(table_name, column_name) +
  " FOREIGN KEY (" +
  column_name +
  ") REFERENCES " +
  target_table +
  "(id)" +
  foreign_key_delete_clause(on_delete) +
  validation_suffix
}

///|
fn foreign_key_constraint_name(
  table_name : String,
  column_name : String,
) -> String {
  "fk_" + table_name + "_" + column_name
}

///|
fn foreign_key_delete_clause(on_delete : String?) -> String {
  match on_delete {
    Some(action) => " ON DELETE " + action
    None => ""
  }
}

///|
fn sql_literal(value : String) -> String {
  "'" + value.replace_all(old="'", new="''") + "'"
}
