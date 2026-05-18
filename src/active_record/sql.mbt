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
    columns.push(quote_sql_identifier(field.0))
    values.push(@support.sql_literal(field.1))
  }
  "INSERT INTO " +
  quote_sql_identifier_path(model.table) +
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
    assignments.push(
      quote_sql_identifier(field.0) + " = " + @support.sql_literal(field.1),
    )
  }
  "UPDATE " +
  quote_sql_identifier_path(model.table) +
  " SET " +
  assignments.join(", ") +
  " WHERE " +
  quote_sql_identifier(model.primary_key) +
  " = " +
  @support.sql_literal(id)
}

///|
/// Renders a `DELETE` or soft-delete statement for a record.
pub fn delete_sql(model : ModelSchema, id : String) -> String {
  if model.soft_delete {
    "UPDATE " +
    quote_sql_identifier_path(model.table) +
    " SET " +
    quote_sql_identifier("deleted_at") +
    " = CURRENT_TIMESTAMP WHERE " +
    quote_sql_identifier(model.primary_key) +
    " = " +
    @support.sql_literal(id)
  } else {
    "DELETE FROM " +
    quote_sql_identifier_path(model.table) +
    " WHERE " +
    quote_sql_identifier(model.primary_key) +
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
    columns.push(quote_sql_identifier(field.0))
    values.push(@support.sql_literal(field.1))
    updates.push(
      quote_sql_identifier(field.0) +
      " = EXCLUDED." +
      quote_sql_identifier(field.0),
    )
  }
  "INSERT INTO " +
  quote_sql_identifier_path(model.table) +
  " (" +
  columns.join(", ") +
  ") VALUES (" +
  values.join(", ") +
  ") ON CONFLICT (" +
  quote_sql_identifier(conflict_column) +
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
  "CREATE TABLE " +
  quote_sql_identifier_path(model.table) +
  " (\n  " +
  definitions.join(",\n  ") +
  "\n)"
}

///|
/// Renders the SQL column definition for one schema column.
pub fn column_definition_sql(column : Column) -> String {
  let null_sql = if column.nullable { "NULL" } else { "NOT NULL" }
  let base = match column.column_type {
    Varchar => quote_sql_identifier(column.name) + " VARCHAR(255) " + null_sql
    Text => quote_sql_identifier(column.name) + " TEXT " + null_sql
    Integer => quote_sql_identifier(column.name) + " INTEGER " + null_sql
    Boolean => quote_sql_identifier(column.name) + " BOOLEAN " + null_sql
    Timestamp => quote_sql_identifier(column.name) + " TIMESTAMP " + null_sql
    Json => quote_sql_identifier(column.name) + " JSON " + null_sql
    References(table) =>
      quote_sql_identifier(column.name) +
      " BIGINT " +
      null_sql +
      " REFERENCES " +
      quote_sql_identifier_path(table) +
      "(" +
      quote_sql_identifier("id") +
      ")"
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
        quote_sql_identifier(index_name) +
        " ON " +
        quote_sql_identifier_path(model.table) +
        " (" +
        quote_sql_identifier(column.name) +
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

///|
fn quote_sql_identifier(source : String) -> String {
  let trimmed = source.trim().to_owned()
  if is_safe_sql_identifier(trimmed) {
    return trimmed
  }
  "\"" + trimmed.replace(old="\"", new="\"\"") + "\""
}

///|
fn quote_sql_identifier_path(source : String) -> String {
  let trimmed = source.trim().to_owned()
  if trimmed == "*" {
    return "*"
  }
  let parts = trimmed.split(".").map(fn(part) { part.to_owned() }).collect()
  if parts.length() <= 1 {
    return quote_sql_identifier(trimmed)
  }
  let quoted : Array[String] = []
  for part in parts {
    let segment = part.trim().to_owned()
    if segment == "*" {
      quoted.push("*")
    } else {
      quoted.push(quote_sql_identifier(segment))
    }
  }
  quoted.join(".")
}

///|
fn is_safe_sql_identifier(source : String) -> Bool {
  if source.length() == 0 {
    return false
  }
  let chars = source.to_array()
  if !is_sql_identifier_start(chars[0]) {
    return false
  }
  let mut index = 1
  while index < chars.length() {
    if !is_sql_identifier_continue(chars[index]) {
      return false
    }
    index += 1
  }
  true
}

///|
fn is_sql_identifier_start(ch : Char) -> Bool {
  (ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z') || ch == '_'
}

///|
fn is_sql_identifier_continue(ch : Char) -> Bool {
  is_sql_identifier_start(ch) || (ch >= '0' && ch <= '9')
}
