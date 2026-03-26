///|
/// Holds the rows stored for one table in the in-memory adapter.
pub struct MemoryTable {
  name : String
  rows : Array[Record]
}

///|
/// Holds all tables stored by the in-memory adapter.
pub struct MemoryDatabase {
  tables : Array[MemoryTable]
}

///|
/// Represents the result of validating and saving a record.
pub enum SaveOutcome {
  Saved(MemoryDatabase, Record)
  ValidationFailed(ValidationErrors)
}

///|
/// Returns an empty in-memory database.
pub fn empty_memory_database() -> MemoryDatabase {
  { tables: [] }
}

///|
/// Inserts a record into the in-memory database.
pub fn insert_record(db : MemoryDatabase, row : Record) -> MemoryDatabase {
  let tables : Array[MemoryTable] = []
  let mut inserted = false
  for table in db.tables {
    if table.name == row.table {
      let rows = @support.clone_array(table.rows)
      rows.push(row)
      tables.push({ name: table.name, rows })
      inserted = true
    } else {
      tables.push(table)
    }
  }
  if not(inserted) {
    tables.push({ name: row.table, rows: [row] })
  }
  { tables, }
}

///|
/// Finds records in the in-memory adapter by exact field value.
pub fn find_records(
  db : MemoryDatabase,
  table_name : String,
  column_name : String,
  value : String,
) -> Array[Record] {
  for table in db.tables {
    if table.name == table_name {
      let rows : Array[Record] = []
      for row in table.rows {
        match @support.find_entry(row.fields, column_name) {
          Some(current_value) => if current_value == value { rows.push(row) }
          None => ()
        }
      }
      return rows
    }
  }
  []
}

///|
/// Validates a record against a schema using the in-memory adapter.
pub fn validate_record_errors(
  schema : ModelSchema,
  row : Record,
  db : MemoryDatabase,
) -> ValidationErrors {
  let errors = validation_errors(model_name=schema.name)
  let mut current = errors
  for validation in schema.validations {
    current = current.merge(validate_rule(schema, validation, row, db))
  }
  current
}

///|
/// Validates a record against a schema using the in-memory adapter.
pub fn validate_record(
  schema : ModelSchema,
  row : Record,
  db : MemoryDatabase,
) -> Array[String] {
  validate_record_errors(schema, row, db).full_messages()
}

///|
/// Validates and inserts a record into the in-memory adapter.
pub fn save_record(
  schema : ModelSchema,
  db : MemoryDatabase,
  row : Record,
) -> SaveOutcome {
  let errors = validate_record_errors(schema, row, db)
  if not(errors.is_empty()) {
    return ValidationFailed(errors)
  }
  Saved(insert_record(db, row), row)
}

///|
fn validate_rule(
  schema : ModelSchema,
  validation : Validation,
  row : Record,
  db : MemoryDatabase,
) -> ValidationErrors {
  match validation.rule {
    Uniqueness => validate_uniqueness_rule(schema, validation, row, db)
    _ => validate_local_rule(schema, validation, row)
  }
}

///|
fn validate_local_rule(
  schema : ModelSchema,
  validation : Validation,
  row : Record,
) -> ValidationErrors {
  match validation_field_schema(validation) {
    Some(field_schema) => {
      let report = @validation.validate_object(
        @validation.object_schema(name=schema.name).with_field(field_schema),
        row.fields,
      )
      validation_report_to_errors(schema.name, report)
    }
    None => validation_errors(model_name=schema.name)
  }
}

///|
fn validate_uniqueness_rule(
  schema : ModelSchema,
  validation : Validation,
  row : Record,
  db : MemoryDatabase,
) -> ValidationErrors {
  match @support.find_entry(row.fields, validation.field) {
    Some(value) => {
      let existing = find_records(db, row.table, validation.field, value)
      if existing.is_empty() {
        validation_errors(model_name=schema.name)
      } else {
        validation_errors(model_name=schema.name).add(
          validation_error(
            attribute=validation.field,
            kind=Taken,
            message=resolve_message(validation, "must be unique", [
              ("value", value),
              ("attribute", validation.field),
            ]),
            details=[("value", value)],
          ),
        )
      }
    }
    None => validation_errors(model_name=schema.name)
  }
}

///|
fn validation_field_schema(validation : Validation) -> @validation.FieldSchema? {
  match validation_field_rule(validation) {
    Some(rule) => {
      let configured = match validation.message {
        Some(message) => rule.with_message(message)
        None => rule
      }
      Some(
        @validation.string_field(name=validation.field).with_rule(configured),
      )
    }
    None => None
  }
}

///|
fn validation_field_rule(validation : Validation) -> @validation.FieldRule? {
  match validation.rule {
    Presence => Some(@validation.required())
    LengthMin(minimum) => Some(@validation.min_length(minimum~))
    LengthMax(maximum) => Some(@validation.max_length(maximum~))
    Inclusion(values) => Some(@validation.included_in(values~))
    Confirmation(other_field) =>
      Some(
        @validation.same_as(other_field~).with_message(
          "confirmation does not match",
        ),
      )
    Format(pattern) =>
      Some(@validation.contains(pattern~).with_message("has invalid format"))
    WrappedRule(rule) => Some(rule)
    Uniqueness => None
  }
}

///|
fn validation_report_to_errors(
  model_name : String,
  report : @validation.ValidationReport,
) -> ValidationErrors {
  let errors = validation_errors(model_name~)
  let mut current = errors
  for issue in report.issues {
    current = current.add(
      validation_error(
        attribute=issue.path,
        kind=rule_kind_to_error_kind(issue.kind),
        message=issue.message,
        details=issue.details,
      ),
    )
  }
  current
}

///|
fn rule_kind_to_error_kind(kind : @validation.RuleKind) -> ValidationErrorKind {
  match kind {
    @validation.Required => Blank
    @validation.MinLength(minimum) => TooShort(minimum)
    @validation.MaxLength(maximum) => TooLong(maximum)
    @validation.IncludedIn(_) => NotIncluded
    @validation.SameAs(other_field) => ConfirmationMismatch(other_field)
    @validation.Contains(pattern) => InvalidFormat(pattern)
  }
}

///|
fn resolve_message(
  validation : Validation,
  default_message : String,
  details : Array[(String, String)],
) -> String {
  let template = match validation.message {
    Some(message) => message
    None => default_message
  }
  let context = @support.clone_array(details)
  context.push(("path", validation.field))
  let mut rendered = template
  for detail in context {
    rendered = rendered.replace(old="%{" + detail.0 + "}", new=detail.1)
  }
  rendered
}
