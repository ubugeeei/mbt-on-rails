///|
/// Lists the SQL column kinds supported by the schema DSL.
pub enum ColumnType {
  Varchar
  Text
  Integer
  Boolean
  Timestamp
  Json
  References(String)
} derive(Eq, Show)

///|
/// Describes one column in a model schema.
pub struct Column {
  name : String
  column_type : ColumnType
  nullable : Bool
  unique : Bool
  indexed : Bool
  default_value : String?
}

///|
/// Describes one model schema in the Active Record-like DSL.
pub struct ModelSchema {
  name : String
  table : String
  primary_key : String
  columns : Array[Column]
  timestamps : Bool
  soft_delete : Bool
  associations : Array[Association]
  validations : Array[Validation]
  callbacks : Array[Callback]
}

///|
/// Builds a required string column.
pub fn string_column(name : String) -> Column {
  {
    name,
    column_type: Varchar,
    nullable: false,
    unique: false,
    indexed: false,
    default_value: None,
  }
}

///|
/// Builds a required text column.
pub fn text_column(name : String) -> Column {
  {
    name,
    column_type: Text,
    nullable: false,
    unique: false,
    indexed: false,
    default_value: None,
  }
}

///|
/// Builds a required integer column.
pub fn integer_column(name : String) -> Column {
  {
    name,
    column_type: Integer,
    nullable: false,
    unique: false,
    indexed: false,
    default_value: None,
  }
}

///|
/// Builds a required boolean column.
pub fn boolean_column(name : String) -> Column {
  {
    name,
    column_type: Boolean,
    nullable: false,
    unique: false,
    indexed: false,
    default_value: None,
  }
}

///|
/// Builds a required timestamp column.
pub fn timestamp_column(name : String) -> Column {
  {
    name,
    column_type: Timestamp,
    nullable: false,
    unique: false,
    indexed: false,
    default_value: None,
  }
}

///|
/// Builds a required JSON column.
pub fn json_column(name : String) -> Column {
  {
    name,
    column_type: Json,
    nullable: false,
    unique: false,
    indexed: false,
    default_value: None,
  }
}

///|
/// Builds a foreign-key-like reference column.
pub fn references_column(name : String, table : String) -> Column {
  {
    name,
    column_type: References(table),
    nullable: false,
    unique: false,
    indexed: true,
    default_value: None,
  }
}

///|
/// Marks a column as nullable.
pub fn nullable(column : Column) -> Column {
  { ..column, nullable: true }
}

///|
/// Marks a column as unique.
pub fn unique(column : Column) -> Column {
  { ..column, unique: true }
}

///|
/// Marks a column as indexed.
pub fn indexed(column : Column) -> Column {
  { ..column, indexed: true }
}

///|
/// Adds a default value to a column.
pub fn with_default(column : Column, default_value : String) -> Column {
  { ..column, default_value: Some(default_value) }
}

///|
/// Builds a model schema with labeled arguments and standard defaults.
#label_migration(name, allow_positional=true)
#label_migration(table, allow_positional=true)
#label_migration(columns, allow_positional=true)
pub fn model(
  name~ : String,
  table~ : String,
  columns~ : Array[Column],
  timestamps? : Bool = true,
  soft_delete? : Bool = false,
) -> ModelSchema {
  {
    name,
    table,
    primary_key: "id",
    columns,
    timestamps,
    soft_delete,
    associations: [],
    validations: [],
    callbacks: [],
  }
}

///|
/// Returns a schema with one more association.
pub fn with_association(
  schema : ModelSchema,
  association : Association,
) -> ModelSchema {
  let associations = @support.clone_array(schema.associations)
  associations.push(association)
  { ..schema, associations, }
}

///|
/// Returns a schema with one more validation.
pub fn with_validation(
  schema : ModelSchema,
  validation : Validation,
) -> ModelSchema {
  let validations = @support.clone_array(schema.validations)
  validations.push(validation)
  { ..schema, validations, }
}

///|
/// Returns a schema with one more callback.
pub fn with_callback(schema : ModelSchema, callback : Callback) -> ModelSchema {
  let callbacks = @support.clone_array(schema.callbacks)
  callbacks.push(callback)
  { ..schema, callbacks, }
}
