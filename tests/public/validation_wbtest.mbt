///|
test "validation library composes valibot-like object schemas" {
  let schema = object_schema(name="SignUp")
    .with_field(string_field(name="email").required().contains("@"))
    .with_field(
      string_field(name="password")
      .min_length(8)
      .same_as("password_confirmation"),
    )

  let report = validate_object(schema, [
    ("email", "invalid"),
    ("password", "short"),
    ("password_confirmation", "different"),
  ])

  assert_eq(report.schema_name, "SignUp")
  assert_true(report.contains_path("email"))
  assert_eq(report.for_path("password").length(), 2)
  assert_true(report.full_messages().contains("email must include @"))
  match report.for_path("password")[0].kind {
    MinLength(limit) => assert_eq(limit, 8)
    _ => assert_true(false)
  }
  assert_eq(report.for_path("password")[0].detail("minimum"), Some("8"))
}

///|
test "active record validations can wrap generic field rules" {
  let schema = model(
    name="Account",
    table="accounts",
    columns=[string_column("email")],
    timestamps=false,
  ).with_validation(
    validates(
      field="email",
      rule=contains(pattern="@").with_message("must look like an email"),
    ),
  )

  let errors = validate_record_errors(
    schema,
    record("accounts", [("email", "invalid")]),
    empty_memory_database(),
  )

  assert_true(errors.full_messages().contains("email must look like an email"))
  match errors.for_attribute("email")[0].kind {
    InvalidFormat(pattern) => assert_eq(pattern, "@")
    _ => assert_true(false)
  }
}
