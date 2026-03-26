///|
/// Builds one form field descriptor with explicit UI metadata.
#label_migration(name, allow_positional=true)
#label_migration(field_kind, allow_positional=true)
#label_migration(label, allow_positional=true)
pub fn form_field(
  name~ : String,
  field_kind~ : FormFieldKind,
  label~ : String,
  required? : Bool = true,
  placeholder? : String? = None,
  value? : String? = None,
  autocomplete? : String? = None,
  help_text? : String? = None,
) -> FormField {
  {
    name,
    field_kind,
    label,
    required,
    placeholder,
    value,
    autocomplete,
    help_text,
  }
}

///|
/// Builds one text input field descriptor.
pub fn text_field(
  name~ : String,
  label~ : String,
  required? : Bool = true,
  placeholder? : String? = None,
  value? : String? = None,
  autocomplete? : String? = None,
  help_text? : String? = None,
) -> FormField {
  form_field(
    name~,
    field_kind=TextInput,
    label~,
    required~,
    placeholder~,
    value~,
    autocomplete~,
    help_text~,
  )
}

///|
/// Builds one email input field descriptor.
pub fn email_field(
  name~ : String,
  label~ : String,
  required? : Bool = true,
  placeholder? : String? = None,
  value? : String? = None,
  autocomplete? : String? = None,
  help_text? : String? = None,
) -> FormField {
  form_field(
    name~,
    field_kind=EmailInput,
    label~,
    required~,
    placeholder~,
    value~,
    autocomplete~,
    help_text~,
  )
}

///|
/// Builds one password input field descriptor.
pub fn password_field(
  name~ : String,
  label~ : String,
  required? : Bool = true,
  placeholder? : String? = None,
  value? : String? = None,
  autocomplete? : String? = None,
  help_text? : String? = None,
) -> FormField {
  form_field(
    name~,
    field_kind=PasswordInput,
    label~,
    required~,
    placeholder~,
    value~,
    autocomplete~,
    help_text~,
  )
}

///|
/// Builds one textarea field descriptor.
pub fn textarea_field(
  name~ : String,
  label~ : String,
  required? : Bool = true,
  placeholder? : String? = None,
  value? : String? = None,
  autocomplete? : String? = None,
  help_text? : String? = None,
) -> FormField {
  form_field(
    name~,
    field_kind=TextArea,
    label~,
    required~,
    placeholder~,
    value~,
    autocomplete~,
    help_text~,
  )
}

///|
/// Builds one hidden field descriptor.
pub fn hidden_field(
  name~ : String,
  label~ : String,
  value? : String? = None,
) -> FormField {
  form_field(name~, field_kind=HiddenInput, label~, required=false, value~)
}

///|
/// Builds one checkbox field descriptor.
pub fn checkbox_field(
  name~ : String,
  label~ : String,
  required? : Bool = false,
  value? : String? = None,
  help_text? : String? = None,
) -> FormField {
  form_field(
    name~,
    field_kind=CheckboxInput,
    label~,
    required~,
    value~,
    help_text~,
  )
}

///|
/// Builds one Rails-style form builder descriptor.
#label_migration(name, allow_positional=true)
#label_migration(binding, allow_positional=true)
#label_migration(fields, allow_positional=true)
#label_migration(submit_label, allow_positional=true)
pub fn form_builder(
  name~ : String,
  binding~ : FormBinding,
  fields~ : Array[FormField],
  submit_label~ : String,
  description? : String? = None,
) -> FormBuilder {
  {
    name,
    binding,
    fields: @support.clone_array(fields),
    submit_label,
    description,
  }
}

///|
/// Attaches one form builder to a page and keeps the binding manifest in sync.
pub fn with_form_builder(
  page : PageModule,
  builder : FormBuilder,
) -> PageModule {
  let forms = @support.clone_array(page.forms)
  if not(forms.any(fn(current) { current.name == builder.binding.name })) {
    forms.push(builder.binding)
  }
  let form_builders = @support.clone_array(page.form_builders)
  form_builders.push(builder)
  { ..page, forms, form_builders }
}
