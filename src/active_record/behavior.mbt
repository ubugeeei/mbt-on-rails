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
} derive(Show)

///|
/// Describes one validation on a model field.
pub struct Validation {
  field : String
  rule : ValidationRule
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
pub fn belongs_to(
  name : String,
  target : String,
  foreign_key : String,
) -> Association {
  { name, target, kind: BelongsTo, foreign_key, optional: false }
}

///|
/// Declares a `has_many` association.
pub fn has_many(
  name : String,
  target : String,
  foreign_key : String,
) -> Association {
  { name, target, kind: HasMany, foreign_key, optional: true }
}

///|
/// Declares a `has_one` association.
pub fn has_one(
  name : String,
  target : String,
  foreign_key : String,
) -> Association {
  { name, target, kind: HasOne, foreign_key, optional: true }
}

///|
/// Declares a `has_and_belongs_to_many` association.
pub fn has_and_belongs_to_many(
  name : String,
  target : String,
  foreign_key : String,
) -> Association {
  { name, target, kind: HasAndBelongsToMany, foreign_key, optional: true }
}

///|
/// Adds a presence validation for a field.
pub fn validates_presence(field : String) -> Validation {
  { field, rule: Presence }
}

///|
/// Adds a uniqueness validation for a field.
pub fn validates_uniqueness(field : String) -> Validation {
  { field, rule: Uniqueness }
}

///|
/// Adds a minimum length validation for a field.
pub fn validates_length_min(field : String, min_ : Int) -> Validation {
  { field, rule: LengthMin(min_) }
}

///|
/// Adds a maximum length validation for a field.
pub fn validates_length_max(field : String, max_ : Int) -> Validation {
  { field, rule: LengthMax(max_) }
}

///|
/// Adds an inclusion validation for a field.
pub fn validates_inclusion(
  field : String,
  values : Array[String],
) -> Validation {
  { field, rule: Inclusion(values) }
}

///|
/// Adds a confirmation validation for a field pair.
pub fn validates_confirmation(
  field : String,
  confirmation_field : String,
) -> Validation {
  { field, rule: Confirmation(confirmation_field) }
}

///|
/// Adds a lightweight format validation for a field.
pub fn validates_format(field : String, pattern : String) -> Validation {
  { field, rule: Format(pattern) }
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
