///|
/// Enumerates the primitive rule kinds supported by the validation DSL.
pub enum RuleKind {
  Required
  MinLength(Int)
  MaxLength(Int)
  IncludedIn(Array[String])
  SameAs(String)
  Contains(String)
} derive(Show)

///|
/// Describes one composable rule in a valibot-like field schema.
pub struct FieldRule {
  kind : RuleKind
  message : String?
} derive(Show)

///|
/// Describes one string field in an object schema.
pub struct FieldSchema {
  name : String
  rules : Array[FieldRule]
}

///|
/// Describes one object schema composed from named fields.
pub struct ObjectSchema {
  name : String
  fields : Array[FieldSchema]
}

///|
/// Represents one typed issue reported by the validation library.
pub struct ValidationIssue {
  path : String
  kind : RuleKind
  message : String
  details : Array[(String, String)]
}

///|
/// Collects the issues found while validating one object schema.
pub struct ValidationReport {
  schema_name : String
  issues : Array[ValidationIssue]
}

///|
/// Starts an empty object schema.
#label_migration(name, allow_positional=true)
pub fn object_schema(name~ : String) -> ObjectSchema {
  { name, fields: [] }
}

///|
/// Starts a string field schema with no rules.
#label_migration(name, allow_positional=true)
pub fn string_field(name~ : String) -> FieldSchema {
  { name, rules: [] }
}

///|
/// Builds a required-field rule.
pub fn required() -> FieldRule {
  { kind: Required, message: None }
}

///|
/// Builds a minimum-length rule.
#label_migration(minimum, allow_positional=true)
pub fn min_length(minimum~ : Int) -> FieldRule {
  { kind: MinLength(minimum), message: None }
}

///|
/// Builds a maximum-length rule.
#label_migration(maximum, allow_positional=true)
pub fn max_length(maximum~ : Int) -> FieldRule {
  { kind: MaxLength(maximum), message: None }
}

///|
/// Builds an inclusion rule.
#label_migration(values, allow_positional=true)
pub fn included_in(values~ : Array[String]) -> FieldRule {
  { kind: IncludedIn(values), message: None }
}

///|
/// Builds a cross-field equality rule.
#label_migration(other_field, allow_positional=true)
pub fn same_as(other_field~ : String) -> FieldRule {
  { kind: SameAs(other_field), message: None }
}

///|
/// Builds a lightweight substring check.
#label_migration(pattern, allow_positional=true)
pub fn contains(pattern~ : String) -> FieldRule {
  { kind: Contains(pattern), message: None }
}

///|
/// Overrides the default message for a field rule.
pub fn FieldRule::with_message(self : FieldRule, message : String) -> FieldRule {
  { ..self, message: Some(message) }
}

///|
/// Appends one field to an object schema.
pub fn ObjectSchema::with_field(
  self : ObjectSchema,
  field : FieldSchema,
) -> ObjectSchema {
  let fields = @support.clone_array(self.fields)
  fields.push(field)
  { ..self, fields, }
}

///|
/// Appends one rule to a field schema.
pub fn FieldSchema::with_rule(
  self : FieldSchema,
  rule : FieldRule,
) -> FieldSchema {
  let rules = @support.clone_array(self.rules)
  rules.push(rule)
  { ..self, rules, }
}

///|
/// Adds a required-field rule to a field schema.
pub fn FieldSchema::required(self : FieldSchema) -> FieldSchema {
  self.with_rule(required())
}

///|
/// Adds a minimum-length rule to a field schema.
pub fn FieldSchema::min_length(
  self : FieldSchema,
  minimum : Int,
) -> FieldSchema {
  self.with_rule(min_length(minimum~))
}

///|
/// Adds a maximum-length rule to a field schema.
pub fn FieldSchema::max_length(
  self : FieldSchema,
  maximum : Int,
) -> FieldSchema {
  self.with_rule(max_length(maximum~))
}

///|
/// Adds an inclusion rule to a field schema.
pub fn FieldSchema::included_in(
  self : FieldSchema,
  values : Array[String],
) -> FieldSchema {
  self.with_rule(included_in(values~))
}

///|
/// Adds a cross-field equality rule to a field schema.
pub fn FieldSchema::same_as(
  self : FieldSchema,
  other_field : String,
) -> FieldSchema {
  self.with_rule(same_as(other_field~))
}

///|
/// Adds a substring rule to a field schema.
pub fn FieldSchema::contains(
  self : FieldSchema,
  pattern : String,
) -> FieldSchema {
  self.with_rule(contains(pattern~))
}

///|
/// Builds an empty validation report for the supplied schema.
#label_migration(schema_name, allow_positional=true)
pub fn validation_report(schema_name~ : String) -> ValidationReport {
  { schema_name, issues: [] }
}

///|
/// Builds one validation issue.
#label_migration(path, allow_positional=true)
#label_migration(kind, allow_positional=true)
#label_migration(message, allow_positional=true)
#label_migration(details, allow_positional=true)
pub fn validation_issue(
  path~ : String,
  kind~ : RuleKind,
  message~ : String,
  details~ : Array[(String, String)],
) -> ValidationIssue {
  { path, kind, message, details }
}

///|
/// Appends one issue to a report.
pub fn ValidationReport::add(
  self : ValidationReport,
  issue : ValidationIssue,
) -> ValidationReport {
  let issues = @support.clone_array(self.issues)
  issues.push(issue)
  { ..self, issues, }
}

///|
/// Merges another report into this one.
pub fn ValidationReport::merge(
  self : ValidationReport,
  other : ValidationReport,
) -> ValidationReport {
  let issues = @support.clone_array(self.issues)
  for issue in other.issues {
    issues.push(issue)
  }
  { ..self, issues, }
}

///|
/// Returns issues matching the supplied path.
pub fn ValidationReport::for_path(
  self : ValidationReport,
  path : String,
) -> Array[ValidationIssue] {
  let matches : Array[ValidationIssue] = []
  for issue in self.issues {
    if issue.path == path {
      matches.push(issue)
    }
  }
  matches
}

///|
/// Returns whether any issue exists for the supplied path.
pub fn ValidationReport::contains_path(
  self : ValidationReport,
  path : String,
) -> Bool {
  for issue in self.issues {
    if issue.path == path {
      return true
    }
  }
  false
}

///|
/// Returns the raw issue messages without path prefixes.
pub fn ValidationReport::messages(self : ValidationReport) -> Array[String] {
  let messages : Array[String] = []
  for issue in self.issues {
    messages.push(issue.message)
  }
  messages
}

///|
/// Returns the full messages including their paths.
pub fn ValidationReport::full_messages(
  self : ValidationReport,
) -> Array[String] {
  let messages : Array[String] = []
  for issue in self.issues {
    messages.push(issue.full_message())
  }
  messages
}

///|
/// Returns whether the report is empty.
pub fn ValidationReport::is_empty(self : ValidationReport) -> Bool {
  self.issues.is_empty()
}

///|
/// Returns the number of issues captured in the report.
pub fn ValidationReport::size(self : ValidationReport) -> Int {
  self.issues.length()
}

///|
/// Renders the report as one summary line.
pub fn ValidationReport::summary(self : ValidationReport) -> String {
  self.full_messages().join(", ")
}

///|
/// Returns one typed issue detail by key.
pub fn ValidationIssue::detail(self : ValidationIssue, key : String) -> String? {
  @support.find_entry(self.details, key)
}

///|
/// Renders the issue as `path + message`.
pub fn ValidationIssue::full_message(self : ValidationIssue) -> String {
  if self.path == "base" {
    self.message
  } else {
    self.path + " " + self.message
  }
}

///|
/// Validates an object against the composed schema.
pub fn validate_object(
  schema : ObjectSchema,
  input : Array[(String, String)],
) -> ValidationReport {
  let report = validation_report(schema_name=schema.name)
  let mut current = report
  for field in schema.fields {
    for rule in field.rules {
      current = apply_rule(current, field.name, rule, input)
    }
  }
  current
}

///|
fn apply_rule(
  report : ValidationReport,
  path : String,
  rule : FieldRule,
  input : Array[(String, String)],
) -> ValidationReport {
  let field_value = @support.find_entry(input, path)
  match rule.kind {
    Required =>
      match field_value {
        Some(value) =>
          if value.trim().to_string().length() == 0 {
            report.add(issue_for(path, rule, Required, "must be present", []))
          } else {
            report
          }
        None =>
          report.add(issue_for(path, rule, Required, "must be present", []))
      }
    MinLength(minimum) =>
      match field_value {
        Some(value) =>
          if value.length() < minimum {
            report.add(
              issue_for(
                path,
                rule,
                MinLength(minimum),
                "must have length >= " + minimum.to_string(),
                [("minimum", minimum.to_string())],
              ),
            )
          } else {
            report
          }
        None => report
      }
    MaxLength(maximum) =>
      match field_value {
        Some(value) =>
          if value.length() > maximum {
            report.add(
              issue_for(
                path,
                rule,
                MaxLength(maximum),
                "must have length <= " + maximum.to_string(),
                [("maximum", maximum.to_string())],
              ),
            )
          } else {
            report
          }
        None => report
      }
    IncludedIn(values) =>
      match field_value {
        Some(value) =>
          if not(values.contains(value)) {
            report.add(
              issue_for(
                path,
                rule,
                IncludedIn(values),
                "is not included in the list",
                [("allowed_values", values.join(","))],
              ),
            )
          } else {
            report
          }
        None => report
      }
    SameAs(other_field) =>
      match field_value {
        Some(left) =>
          match @support.find_entry(input, other_field) {
            Some(right) =>
              if left != right {
                report.add(
                  issue_for(
                    path,
                    rule,
                    SameAs(other_field),
                    "must match " + other_field,
                    [("other_field", other_field)],
                  ),
                )
              } else {
                report
              }
            None => report
          }
        None => report
      }
    Contains(pattern) =>
      match field_value {
        Some(value) =>
          if not(value.contains(pattern)) {
            report.add(
              issue_for(
                path,
                rule,
                Contains(pattern),
                "must include " + pattern,
                [("pattern", pattern)],
              ),
            )
          } else {
            report
          }
        None => report
      }
  }
}

///|
fn issue_for(
  path : String,
  rule : FieldRule,
  kind : RuleKind,
  default_message : String,
  details : Array[(String, String)],
) -> ValidationIssue {
  let message = match rule.message {
    Some(message) => message
    None => default_message
  }
  validation_issue(path~, kind~, message~, details~)
}
