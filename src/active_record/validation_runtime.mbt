///|
/// Validates a record against a schema using the in-memory adapter.
pub fn validate_record_errors(
  schema : ModelSchema,
  row : Record,
  db : MemoryDatabase,
) -> ValidationErrors {
  let errors = validation_errors(model_name=schema.name)
  let mut current = errors
  for validation in effective_validations(schema) {
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
      let conflicts = matching_unique_conflicts(
        schema,
        db,
        row,
        validation.field,
        value,
      )
      if conflicts.length() == 0 {
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
fn matching_unique_conflicts(
  schema : ModelSchema,
  db : MemoryDatabase,
  row : Record,
  attribute : String,
  value : String,
) -> Array[Record] {
  let conflicts : Array[Record] = []
  for current in find_records(db, row.table, attribute, value) {
    if not(same_primary_key(schema, current, row)) {
      conflicts.push(current)
    }
  }
  conflicts
}

///|
fn effective_validations(schema : ModelSchema) -> Array[Validation] {
  let validations = @support.clone_array(schema.validations)
  for column in schema.columns {
    if column.unique && not(has_uniqueness_validation(validations, column.name)) {
      validations.push(validates_uniqueness(field=column.name))
    }
  }
  validations
}

///|
fn has_uniqueness_validation(
  validations : Array[Validation],
  field : String,
) -> Bool {
  for validation in validations {
    if validation.field == field {
      match validation.rule {
        Uniqueness => return true
        _ => ()
      }
    }
  }
  false
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

///|
fn same_primary_key(
  schema : ModelSchema,
  left : Record,
  right : Record,
) -> Bool {
  match @support.find_entry(left.fields, schema.primary_key) {
    Some(left_value) =>
      match @support.find_entry(right.fields, schema.primary_key) {
        Some(right_value) => left_value == right_value
        None => false
      }
    None => false
  }
}
