///|
/// Represents one record payload to be written to a table.
pub struct Record {
  table : String
  fields : Array[(String, String)]
}

///|
/// Builds a record payload for a table.
pub fn record(table : String, fields : Array[(String, String)]) -> Record {
  { table, fields }
}

///|
/// Renders an `INSERT` statement for a record.
pub fn insert_sql(model : ModelSchema, row : Record) -> String {
  let columns : Array[String] = []
  let values : Array[String] = []
  for field in row.fields {
    columns.push(field.0)
    values.push(@support.sql_literal(field.1))
  }
  "INSERT INTO " +
  model.table +
  " (" +
  columns.join(", ") +
  ") VALUES (" +
  values.join(", ") +
  ")"
}

///|
/// Renders an `UPDATE` statement for a record by primary key.
pub fn update_sql(model : ModelSchema, row : Record, id : String) -> String {
  let assignments : Array[String] = []
  for field in row.fields {
    assignments.push(field.0 + " = " + @support.sql_literal(field.1))
  }
  "UPDATE " +
  model.table +
  " SET " +
  assignments.join(", ") +
  " WHERE " +
  model.primary_key +
  " = " +
  @support.sql_literal(id)
}

///|
/// Renders a `DELETE` or soft-delete statement for a record.
pub fn delete_sql(model : ModelSchema, id : String) -> String {
  if model.soft_delete {
    "UPDATE " +
    model.table +
    " SET deleted_at = CURRENT_TIMESTAMP WHERE " +
    model.primary_key +
    " = " +
    @support.sql_literal(id)
  } else {
    "DELETE FROM " +
    model.table +
    " WHERE " +
    model.primary_key +
    " = " +
    @support.sql_literal(id)
  }
}

///|
/// Renders an `UPSERT` statement using one conflict column.
pub fn upsert_sql(
  model : ModelSchema,
  row : Record,
  conflict_column : String,
) -> String {
  let columns : Array[String] = []
  let values : Array[String] = []
  let updates : Array[String] = []
  for field in row.fields {
    columns.push(field.0)
    values.push(@support.sql_literal(field.1))
    updates.push(field.0 + " = EXCLUDED." + field.0)
  }
  "INSERT INTO " +
  model.table +
  " (" +
  columns.join(", ") +
  ") VALUES (" +
  values.join(", ") +
  ") ON CONFLICT (" +
  conflict_column +
  ") DO UPDATE SET " +
  updates.join(", ")
}

///|
/// Renders a `CREATE TABLE` statement for a model schema.
pub fn create_table_sql(model : ModelSchema) -> String {
  let definitions : Array[String] = ["id BIGINT PRIMARY KEY"]
  for column in model.columns {
    definitions.push(column_definition_sql(column))
  }
  if model.timestamps {
    definitions.push("created_at TIMESTAMP NOT NULL")
    definitions.push("updated_at TIMESTAMP NOT NULL")
  }
  if model.soft_delete {
    definitions.push("deleted_at TIMESTAMP NULL")
  }
  "CREATE TABLE " + model.table + " (\n  " + definitions.join(",\n  ") + "\n)"
}

///|
/// Renders the SQL column definition for one schema column.
pub fn column_definition_sql(column : Column) -> String {
  let null_sql = if column.nullable { "NULL" } else { "NOT NULL" }
  let base = match column.column_type {
    Varchar => column.name + " VARCHAR(255) " + null_sql
    Text => column.name + " TEXT " + null_sql
    Integer => column.name + " INTEGER " + null_sql
    Boolean => column.name + " BOOLEAN " + null_sql
    Timestamp => column.name + " TIMESTAMP " + null_sql
    Json => column.name + " JSON " + null_sql
    References(table) =>
      column.name + " BIGINT " + null_sql + " REFERENCES " + table + "(id)"
  }
  let with_default = match column.default_value {
    Some(default_value) =>
      base + " DEFAULT " + @support.sql_literal(default_value)
    None => base
  }
  if column.unique {
    with_default + " UNIQUE"
  } else {
    with_default
  }
}

///|
/// Renders the index statements implied by a model schema.
pub fn index_statements(model : ModelSchema) -> Array[String] {
  let statements : Array[String] = []
  for column in model.columns {
    if column.indexed || column.unique {
      let unique_prefix = if column.unique { "UNIQUE " } else { "" }
      let index_name = "idx_" + model.table + "_" + column.name
      statements.push(
        "CREATE " +
        unique_prefix +
        "INDEX " +
        index_name +
        " ON " +
        model.table +
        " (" +
        column.name +
        ")",
      )
    }
  }
  statements
}

///|
/// Renders a simple schema dump for a list of models.
pub fn schema_dump(models : Array[ModelSchema]) -> String {
  let lines : Array[String] = []
  for model in models {
    lines.push(create_table_sql(model))
    for index_sql in index_statements(model) {
      lines.push(index_sql)
    }
  }
  lines.join("\n")
}
