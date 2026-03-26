///|
fn create_table_statements(model : @orm.ModelSchema) -> Array[String] {
  let statements = [@orm.create_table_sql(model)]
  for index_sql in @orm.index_statements(model) {
    statements.push(index_sql)
  }
  statements
}

///|
fn add_reference_statements(
  table_name : String,
  column_name : String,
  target_table : String,
  nullable : Bool,
  unique : Bool,
  default_value : String?,
) -> Array[String] {
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

///|
fn add_timestamps_statements(
  table_name : String,
  nullable : Bool,
) -> Array[String] {
  let null_sql = if nullable { "NULL" } else { "NOT NULL" }
  [
    "ALTER TABLE " + table_name + " ADD COLUMN created_at TIMESTAMP " + null_sql,
    "ALTER TABLE " + table_name + " ADD COLUMN updated_at TIMESTAMP " + null_sql,
  ]
}

///|
fn drop_created_table_statements(model : @orm.ModelSchema) -> Array[String] {
  let statements : Array[String] = []
  for column in model.columns {
    if column.indexed || column.unique {
      statements.push("DROP INDEX " + index_name(model.table, column.name))
    }
  }
  statements.push("DROP TABLE " + model.table)
  statements
}

///|
fn restore_check_constraint_statements(
  table_name : String,
  constraint_name : String,
  expression : String?,
  validate : Bool,
) -> Array[String] {
  match expression {
    Some(current) =>
      [
        check_constraint_statement(
          table_name, constraint_name, current, validate,
        ),
      ]
    None =>
      ["-- constraint " + constraint_name + " cannot be restored automatically"]
  }
}
