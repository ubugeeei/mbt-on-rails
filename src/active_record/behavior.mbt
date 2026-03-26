///|
/// Lists the association shapes supported by the model DSL.
pub enum AssociationKind {
  BelongsTo
  HasMany
  HasOne
  HasAndBelongsToMany
} derive(Eq, Show)

///|
/// Describes one association declared on a model schema.
pub struct Association {
  name : String
  target : String
  kind : AssociationKind
  foreign_key : String
  optional : Bool
}

///|
/// Lists the validation rules supported by the model DSL.
pub enum ValidationRule {
  Presence
  Uniqueness
  LengthMin(Int)
  LengthMax(Int)
  Inclusion(Array[String])
  Confirmation(String)
  Format(String)
  WrappedRule(@validation.FieldRule)
} derive(Show)

///|
/// Describes one validation on a model field.
pub struct Validation {
  field : String
  rule : ValidationRule
  message : String?
}

///|
/// Enumerates the typed validation error kinds surfaced by the ORM.
pub enum ValidationErrorKind {
  Blank
  Taken
  TooShort(Int)
  TooLong(Int)
  NotIncluded
  ConfirmationMismatch(String)
  InvalidFormat(String)
} derive(Eq, Show)

///|
/// Captures one typed validation error for a model attribute.
pub struct ValidationError {
  attribute : String
  kind : ValidationErrorKind
  message : String
  details : Array[(String, String)]
}

///|
/// Collects the validation errors attached to one model instance.
pub struct ValidationErrors {
  model_name : String
  errors : Array[ValidationError]
}

///|
/// Lists the lifecycle hooks available for callbacks.
pub enum LifecycleHook {
  BeforeValidation
  BeforeCreate
  BeforeSave
  AfterSave
  AfterCreate
  BeforeDestroy
  AfterDestroy
} derive(Eq, Show)

///|
/// Describes one callback attached to a model lifecycle hook.
pub struct Callback {
  hook : LifecycleHook
  function_name : String
}

///|
/// Declares a `belongs_to` association.
#label_migration(name, allow_positional=true)
#label_migration(target, allow_positional=true)
#label_migration(foreign_key, allow_positional=true)
pub fn belongs_to(
  name~ : String,
  target~ : String,
  foreign_key~ : String,
) -> Association {
  { name, target, kind: BelongsTo, foreign_key, optional: false }
}

///|
/// Declares a `has_many` association.
#label_migration(name, allow_positional=true)
#label_migration(target, allow_positional=true)
#label_migration(foreign_key, allow_positional=true)
pub fn has_many(
  name~ : String,
  target~ : String,
  foreign_key~ : String,
) -> Association {
  { name, target, kind: HasMany, foreign_key, optional: true }
}

///|
/// Declares a `has_one` association.
#label_migration(name, allow_positional=true)
#label_migration(target, allow_positional=true)
#label_migration(foreign_key, allow_positional=true)
pub fn has_one(
  name~ : String,
  target~ : String,
  foreign_key~ : String,
) -> Association {
  { name, target, kind: HasOne, foreign_key, optional: true }
}

///|
/// Declares a `has_and_belongs_to_many` association.
#label_migration(name, allow_positional=true)
#label_migration(target, allow_positional=true)
#label_migration(foreign_key, allow_positional=true)
pub fn has_and_belongs_to_many(
  name~ : String,
  target~ : String,
  foreign_key~ : String,
) -> Association {
  { name, target, kind: HasAndBelongsToMany, foreign_key, optional: true }
}

///|
/// Adds a presence validation for a field.
#label_migration(field, allow_positional=true)
pub fn validates_presence(field~ : String) -> Validation {
  { field, rule: Presence, message: None }
}

///|
/// Adds a uniqueness validation for a field.
#label_migration(field, allow_positional=true)
pub fn validates_uniqueness(field~ : String) -> Validation {
  { field, rule: Uniqueness, message: None }
}

///|
/// Adds a minimum length validation for a field.
#label_migration(field, allow_positional=true)
#label_migration(minimum, allow_positional=true)
pub fn validates_length_min(field~ : String, minimum~ : Int) -> Validation {
  { field, rule: LengthMin(minimum), message: None }
}

///|
/// Adds a maximum length validation for a field.
#label_migration(field, allow_positional=true)
#label_migration(maximum, allow_positional=true)
pub fn validates_length_max(field~ : String, maximum~ : Int) -> Validation {
  { field, rule: LengthMax(maximum), message: None }
}

///|
/// Adds an inclusion validation for a field.
#label_migration(field, allow_positional=true)
#label_migration(values, allow_positional=true)
pub fn validates_inclusion(
  field~ : String,
  values~ : Array[String],
) -> Validation {
  { field, rule: Inclusion(values), message: None }
}

///|
/// Adds a confirmation validation for a field pair.
#label_migration(field, allow_positional=true)
#label_migration(confirmation_field, allow_positional=true)
pub fn validates_confirmation(
  field~ : String,
  confirmation_field~ : String,
) -> Validation {
  { field, rule: Confirmation(confirmation_field), message: None }
}

///|
/// Adds a lightweight format validation for a field.
#label_migration(field, allow_positional=true)
#label_migration(pattern, allow_positional=true)
pub fn validates_format(field~ : String, pattern~ : String) -> Validation {
  { field, rule: Format(pattern), message: None }
}

///|
/// Wraps a generic validation-library rule for use in Active Record models.
#label_migration(field, allow_positional=true)
#label_migration(rule, allow_positional=true)
pub fn validates(field~ : String, rule~ : @validation.FieldRule) -> Validation {
  { field, rule: WrappedRule(rule), message: None }
}

///|
/// Overrides the default message for a validation rule.
pub fn Validation::with_message(
  self : Validation,
  message : String,
) -> Validation {
  { ..self, message: Some(message) }
}

///|
/// Builds an empty typed validation error collection for one model.
#label_migration(model_name, allow_positional=true)
pub fn validation_errors(model_name~ : String) -> ValidationErrors {
  { model_name, errors: [] }
}

///|
/// Builds a typed validation error.
#label_migration(attribute, allow_positional=true)
#label_migration(kind, allow_positional=true)
#label_migration(message, allow_positional=true)
#label_migration(details, allow_positional=true)
pub fn validation_error(
  attribute~ : String,
  kind~ : ValidationErrorKind,
  message~ : String,
  details~ : Array[(String, String)],
) -> ValidationError {
  { attribute, kind, message, details }
}

///|
/// Appends one error to the collection.
pub fn ValidationErrors::add(
  self : ValidationErrors,
  error : ValidationError,
) -> ValidationErrors {
  let errors = @support.clone_array(self.errors)
  errors.push(error)
  { ..self, errors, }
}

///|
/// Merges another error collection into this one.
pub fn ValidationErrors::merge(
  self : ValidationErrors,
  other : ValidationErrors,
) -> ValidationErrors {
  let errors = @support.clone_array(self.errors)
  for error in other.errors {
    errors.push(error)
  }
  { ..self, errors, }
}

///|
/// Returns errors matching one attribute.
pub fn ValidationErrors::for_attribute(
  self : ValidationErrors,
  attribute : String,
) -> Array[ValidationError] {
  let matches : Array[ValidationError] = []
  for error in self.errors {
    if error.attribute == attribute {
      matches.push(error)
    }
  }
  matches
}

///|
/// Returns whether any error exists for the supplied attribute.
pub fn ValidationErrors::contains_attribute(
  self : ValidationErrors,
  attribute : String,
) -> Bool {
  for error in self.errors {
    if error.attribute == attribute {
      return true
    }
  }
  false
}

///|
/// Returns the message bodies without the attribute prefix.
pub fn ValidationErrors::messages(self : ValidationErrors) -> Array[String] {
  let messages : Array[String] = []
  for error in self.errors {
    messages.push(error.message)
  }
  messages
}

///|
/// Returns the full messages including attribute prefixes.
pub fn ValidationErrors::full_messages(
  self : ValidationErrors,
) -> Array[String] {
  let messages : Array[String] = []
  for error in self.errors {
    messages.push(error.full_message())
  }
  messages
}

///|
/// Returns the full messages for one attribute.
pub fn ValidationErrors::full_messages_for(
  self : ValidationErrors,
  attribute : String,
) -> Array[String] {
  let messages : Array[String] = []
  for error in self.errors {
    if error.attribute == attribute {
      messages.push(error.full_message())
    }
  }
  messages
}

///|
/// Returns whether the collection has no errors.
pub fn ValidationErrors::is_empty(self : ValidationErrors) -> Bool {
  self.errors.is_empty()
}

///|
/// Returns the number of typed errors in the collection.
pub fn ValidationErrors::size(self : ValidationErrors) -> Int {
  self.errors.length()
}

///|
/// Renders the collection as a single summary line.
pub fn ValidationErrors::summary(self : ValidationErrors) -> String {
  self.full_messages().join(", ")
}

///|
/// Returns one typed detail value by key.
pub fn ValidationError::detail(self : ValidationError, key : String) -> String? {
  @support.find_entry(self.details, key)
}

///|
/// Renders the full message in Rails-like `attribute + message` form.
pub fn ValidationError::full_message(self : ValidationError) -> String {
  if self.attribute == "base" {
    self.message
  } else {
    self.attribute + " " + self.message
  }
}

///|
/// Declares a callback that runs before validation.
pub fn before_validation(function_name : String) -> Callback {
  { hook: BeforeValidation, function_name }
}

///|
/// Declares a callback that runs before save.
pub fn before_save(function_name : String) -> Callback {
  { hook: BeforeSave, function_name }
}

///|
/// Declares a callback that runs before create.
pub fn before_create(function_name : String) -> Callback {
  { hook: BeforeCreate, function_name }
}

///|
/// Declares a callback that runs after save.
pub fn after_save(function_name : String) -> Callback {
  { hook: AfterSave, function_name }
}

///|
/// Declares a callback that runs after create.
pub fn after_create(function_name : String) -> Callback {
  { hook: AfterCreate, function_name }
}

///|
/// Declares a callback that runs before destroy.
pub fn before_destroy(function_name : String) -> Callback {
  { hook: BeforeDestroy, function_name }
}

///|
/// Declares a callback that runs after destroy.
pub fn after_destroy(function_name : String) -> Callback {
  { hook: AfterDestroy, function_name }
}
