///|
/// Builds a schema that exercises validation and save branches.
fn account_schema() -> ModelSchema {
  let base = model(
    name="Account",
    table="accounts",
    columns=[string_column("title")],
    timestamps=false,
  )
  let with_presence = with_validation(base, validates_presence(field="title"))
  let with_required_category = with_validation(
    with_presence,
    validates_presence(field="category"),
  )
  let with_unique_slug = with_validation(
    with_required_category,
    validates_uniqueness(field="slug"),
  )
  let with_min_body = with_validation(
    with_unique_slug,
    validates_length_min(field="body", minimum=10),
  )
  let with_max_summary = with_validation(
    with_min_body,
    validates_length_max(field="summary", maximum=5),
  )
  let with_inclusion = with_validation(
    with_max_summary,
    validates_inclusion(field="state", values=["published", "archived"]),
  )
  let with_confirmation = with_validation(
    with_inclusion,
    validates_confirmation(
      field="password",
      confirmation_field="password_confirmation",
    ),
  )
  with_validation(
    with_confirmation,
    validates_format(field="email", pattern="@"),
  )
}

///|
test "active record constructors expose association validation and callback metadata" {
  let profile = has_one(name="profile", target="Profile", foreign_key="user_id")
  let groups = has_and_belongs_to_many(
    name="groups",
    target="Group",
    foreign_key="user_id",
  )
  assert_eq(profile.kind.to_string(), "HasOne")
  assert_true(profile.optional)
  assert_eq(groups.kind.to_string(), "HasAndBelongsToMany")
  assert_true(groups.optional)

  match validates_length_min(field="body", minimum=10).rule {
    LengthMin(limit) => assert_eq(limit, 10)
    _ => assert_true(false)
  }
  match validates_length_max(field="summary", maximum=5).rule {
    LengthMax(limit) => assert_eq(limit, 5)
    _ => assert_true(false)
  }
  match validates_inclusion(field="state", values=["draft", "published"]).rule {
    Inclusion(values) => assert_eq(values.length(), 2)
    _ => assert_true(false)
  }

  let callbacks = [
    before_validation("normalize"),
    before_create("allocate_id"),
    before_save("stamp"),
    after_save("notify"),
    after_create("index"),
    before_destroy("archive"),
    after_destroy("purge"),
  ]
  assert_eq(callbacks[1].hook.to_string(), "BeforeCreate")
  assert_eq(callbacks[3].hook.to_string(), "AfterSave")
  assert_eq(callbacks[4].hook.to_string(), "AfterCreate")
  assert_eq(callbacks[5].hook.to_string(), "BeforeDestroy")
  assert_eq(callbacks[6].hook.to_string(), "AfterDestroy")
}

///|
test "memory validation reports rich errors across edge branches" {
  let schema = account_schema()
  let db = insert_record(
    empty_memory_database(),
    record("accounts", [("slug", "taken")]),
  )

  let missing = record("accounts", [
    ("title", ""),
    ("summary", "toolong"),
    ("state", "draft"),
    ("password", "secret"),
    ("password_confirmation", "different"),
    ("email", "invalid"),
  ])
  let missing_errors = validate_record(schema, missing, db)
  assert_true(missing_errors.contains("title must be present"))
  assert_true(missing_errors.contains("category must be present"))
  assert_true(missing_errors.contains("summary must have length <= 5"))
  assert_true(missing_errors.contains("state is not included in the list"))
  assert_true(missing_errors.contains("password confirmation does not match"))
  assert_true(missing_errors.contains("email has invalid format"))

  let typed_missing = validate_record_errors(schema, missing, db)
  assert_eq(typed_missing.model_name, "Account")
  assert_true(typed_missing.contains_attribute("title"))
  match typed_missing.for_attribute("summary")[0].kind {
    TooLong(limit) => assert_eq(limit, 5)
    _ => assert_true(false)
  }
  assert_eq(
    typed_missing.for_attribute("summary")[0].detail("maximum"),
    Some("5"),
  )
  assert_true(
    typed_missing
    .full_messages_for("email")
    .contains("email has invalid format"),
  )

  let duplicate = record("accounts", [
    ("title", "Launch"),
    ("category", "announcements"),
    ("slug", "taken"),
    ("body", "short"),
    ("summary", "brief"),
    ("state", "published"),
    ("password", "secret"),
    ("password_confirmation", "secret"),
    ("email", "hello@example.com"),
  ])
  let duplicate_errors = validate_record(schema, duplicate, db)
  assert_true(duplicate_errors.contains("slug must be unique"))
  assert_true(duplicate_errors.contains("body must have length >= 10"))
}

///|
test "save_record persists valid rows and preserves other tables" {
  let schema = account_schema()
  let db = insert_record(
    insert_record(empty_memory_database(), record("users", [("id", "1")])),
    record("accounts", [("slug", "taken")]),
  )
  let expanded = insert_record(db, record("users", [("id", "2")]))
  assert_eq(expanded.tables.length(), 2)

  let searchable = insert_record(
    expanded,
    record("users", [("id", "3"), ("email", "three@example.com")]),
  )
  assert_eq(
    find_records(searchable, "users", "email", "three@example.com").length(),
    1,
  )

  let invalid = record("accounts", [
    ("title", "Launch"),
    ("category", "announcements"),
    ("slug", "taken"),
    ("body", "short"),
    ("summary", "brief"),
    ("state", "published"),
    ("password", "secret"),
    ("password_confirmation", "secret"),
    ("email", "hello@example.com"),
  ])
  match save_record(schema, expanded, invalid) {
    ValidationFailed(errors) =>
      assert_true(errors.full_messages().contains("slug must be unique"))
    Saved(_, _) => assert_true(false)
  }

  let valid = record("accounts", [
    ("title", "Launch"),
    ("category", "announcements"),
    ("slug", "fresh"),
    ("body", "Long enough body"),
    ("summary", "brief"),
    ("state", "published"),
    ("password", "secret"),
    ("password_confirmation", "secret"),
    ("email", "hello@example.com"),
  ])
  match save_record(schema, expanded, valid) {
    Saved(saved_db, saved) => {
      assert_eq(saved.table, "accounts")
      assert_eq(find_records(saved_db, "accounts", "slug", "fresh").length(), 1)
    }
    ValidationFailed(_) => assert_true(false)
  }
}

///|
test "dirty tracking reports changed removed and added attributes" {
  let original = record("accounts", [
    ("title", "Launch"),
    ("state", "draft"),
    ("summary", "brief"),
  ])
  let current = record("accounts", [
    ("title", "Shipped"),
    ("summary", "brief"),
    ("slug", "launch"),
  ])

  let dirty = original.track_changes(current)
  assert_true(dirty.changed())
  assert_eq(dirty.changed_fields(), ["title", "state", "slug"])
  assert_true(dirty.attribute_changed("state"))
  assert_eq(dirty.attribute_was("state"), Some("draft"))
  assert_eq(dirty.attribute_was("summary"), Some("brief"))
  assert_true(dirty.changes_summary().contains("title: Launch -> Shipped"))
  assert_true(dirty.changes_summary().contains("state: draft -> <unset>"))
  assert_true(dirty.changes_summary().contains("slug: <unset> -> launch"))

  match dirty.change_for("title") {
    Some(change) => {
      assert_eq(change.before, Some("Launch"))
      assert_eq(change.after, Some("Shipped"))
    }
    None => assert_true(false)
  }

  let applied = dirty.apply()
  assert_eq(applied.table, "accounts")
  assert_eq(applied.fields.length(), 3)

  let persisted = dirty.clear_changes_information()
  assert_false(persisted.changed())
  assert_eq(persisted.changed_fields().length(), 0)
  assert_eq(persisted.attribute_was("slug"), Some("launch"))

  let created = dirty_new_record(record("accounts", [("slug", "fresh")]))
  assert_true(created.changed())
  assert_true(created.changes_summary().contains("slug: <unset> -> fresh"))
}

///|
test "memory transactions support savepoints rollback and validation-aware saves" {
  let schema = account_schema()
  let db = insert_record(
    empty_memory_database(),
    record("accounts", [("slug", "taken")]),
  )
  let staged = db
    .begin_transaction()
    .insert(record("accounts", [("slug", "draft")]))
    .savepoint("after_draft")
    .insert(record("accounts", [("slug", "temp")]))

  assert_eq(staged.find_records("accounts", "slug", "draft").length(), 1)
  assert_eq(staged.find_records("accounts", "slug", "temp").length(), 1)

  let rolled = staged.rollback_to("after_draft")
  assert_eq(rolled.find_records("accounts", "slug", "draft").length(), 1)
  assert_eq(rolled.find_records("accounts", "slug", "temp").length(), 0)

  let invalid = record("accounts", [
    ("title", "Launch"),
    ("category", "announcements"),
    ("slug", "taken"),
    ("body", "Long enough body"),
    ("summary", "brief"),
    ("state", "published"),
    ("password", "secret"),
    ("password_confirmation", "secret"),
    ("email", "hello@example.com"),
  ])

  match rolled.save(schema, invalid) {
    TransactionValidationFailed(same_tx, errors) => {
      assert_true(errors.full_messages().contains("slug must be unique"))
      assert_eq(same_tx.find_records("accounts", "slug", "taken").length(), 1)
      assert_eq(same_tx.find_records("accounts", "slug", "draft").length(), 1)
    }
    TransactionSaved(_, _) => assert_true(false)
  }

  let valid = record("accounts", [
    ("title", "Launch"),
    ("category", "announcements"),
    ("slug", "fresh"),
    ("body", "Long enough body"),
    ("summary", "brief"),
    ("state", "published"),
    ("password", "secret"),
    ("password_confirmation", "secret"),
    ("email", "hello@example.com"),
  ])

  match rolled.save(schema, valid) {
    TransactionSaved(saved_tx, saved) => {
      assert_eq(saved.table, "accounts")
      let committed = saved_tx.commit()
      assert_eq(
        find_records(committed, "accounts", "slug", "fresh").length(),
        1,
      )
      let reverted = saved_tx.rollback()
      assert_eq(find_records(reverted, "accounts", "slug", "fresh").length(), 0)
      assert_eq(find_records(reverted, "accounts", "slug", "draft").length(), 0)
    }
    TransactionValidationFailed(_, _) => assert_true(false)
  }
}
