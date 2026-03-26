///|
fn article_schema() -> ModelSchema {
  model(
    name="Article",
    table="articles",
    columns=[
      string_column("title"),
      string_column("slug").unique(),
      string_column("state"),
    ],
    timestamps=false,
  )
}

///|
fn audit_schema() -> ModelSchema {
  model(
    name="AuditEntry",
    table="audit_entries",
    columns=[string_column("state")],
    timestamps=false,
    soft_delete=true,
  )
}

///|
fn post_schema() -> ModelSchema {
  model(name="Post", table="posts", columns=[
    string_column("title"),
    string_column("slug").unique(),
    string_column("state").with_default("draft"),
  ])
}

///|
test "save_record updates matching primary keys and preserves existing fields" {
  let schema = article_schema()
  let db = insert_record(
    empty_memory_database(),
    record("articles", [
      ("id", "1"),
      ("title", "Launch"),
      ("slug", "launch"),
      ("state", "draft"),
    ]),
  )

  match
    save_record(
      schema,
      db,
      record("articles", [("id", "1"), ("state", "published")]),
    ) {
    Saved(saved_db, saved) => {
      assert_eq(
        find_records(saved_db, "articles", "slug", "launch").length(),
        1,
      )
      assert_eq(find_entry(saved.fields, "title"), Some("Launch"))
      assert_eq(find_entry(saved.fields, "state"), Some("published"))
      match find_record_by_primary_key(schema, saved_db, "1") {
        Some(current) => {
          assert_eq(find_entry(current.fields, "title"), Some("Launch"))
          assert_eq(find_entry(current.fields, "slug"), Some("launch"))
          assert_eq(find_entry(current.fields, "state"), Some("published"))
        }
        None => assert_true(false)
      }
    }
    ValidationFailed(_) => assert_true(false)
  }

  let conflicting = record("articles", [
    ("id", "2"),
    ("title", "Conflict"),
    ("slug", "launch"),
    ("state", "draft"),
  ])
  match save_record(schema, db, conflicting) {
    Saved(_, _) => assert_true(false)
    ValidationFailed(errors) =>
      assert_true(errors.full_messages().contains("slug must be unique"))
  }
}

///|
test "save_record applies defaults and timestamp fields" {
  let schema = post_schema()

  match
    save_record(
      schema,
      empty_memory_database(),
      record("posts", [("id", "1"), ("title", "Launch"), ("slug", "launch")]),
    ) {
    Saved(_, created) => {
      assert_eq(find_entry(created.fields, "state"), Some("draft"))
      assert_eq(
        find_entry(created.fields, "created_at"),
        Some("CURRENT_TIMESTAMP"),
      )
      assert_eq(
        find_entry(created.fields, "updated_at"),
        Some("CURRENT_TIMESTAMP"),
      )
    }
    ValidationFailed(_) => assert_true(false)
  }

  let existing = insert_record(
    empty_memory_database(),
    record("posts", [
      ("id", "1"),
      ("title", "Launch"),
      ("slug", "launch"),
      ("state", "draft"),
      ("created_at", "2026-03-01T00:00:00Z"),
      ("updated_at", "2026-03-01T00:00:00Z"),
    ]),
  )
  match
    save_record(
      schema,
      existing,
      record("posts", [("id", "1"), ("title", "Shipped")]),
    ) {
    Saved(_, updated) => {
      assert_eq(find_entry(updated.fields, "slug"), Some("launch"))
      assert_eq(find_entry(updated.fields, "state"), Some("draft"))
      assert_eq(
        find_entry(updated.fields, "created_at"),
        Some("2026-03-01T00:00:00Z"),
      )
      assert_eq(
        find_entry(updated.fields, "updated_at"),
        Some("CURRENT_TIMESTAMP"),
      )
    }
    ValidationFailed(_) => assert_true(false)
  }
}

///|
test "destroy_record removes rows or writes deleted_at tombstones" {
  let hard_schema = article_schema()
  let soft_schema = audit_schema()
  let db = insert_record(
    insert_record(
      empty_memory_database(),
      record("articles", [
        ("id", "1"),
        ("title", "Launch"),
        ("slug", "launch"),
        ("state", "draft"),
      ]),
    ),
    record("audit_entries", [("id", "9"), ("state", "active")]),
  )

  match destroy_record(hard_schema, db, "1") {
    DestroyedRecord(after_hard_delete, deleted) => {
      assert_eq(deleted.table, "articles")
      assert_eq(
        find_records(after_hard_delete, "articles", "id", "1").length(),
        0,
      )
      match
        after_hard_delete.destroy(
          soft_schema,
          "9",
          deleted_at=Some("2026-03-27T00:00:00Z"),
        ) {
        DestroyedRecord(after_soft_delete, tombstone) => {
          assert_eq(
            find_records(after_soft_delete, "audit_entries", "id", "9").length(),
            1,
          )
          assert_eq(
            find_entry(tombstone.fields, "deleted_at"),
            Some("2026-03-27T00:00:00Z"),
          )
          match
            find_record_by_primary_key(soft_schema, after_soft_delete, "9") {
            Some(current) =>
              assert_eq(
                find_entry(current.fields, "deleted_at"),
                Some("2026-03-27T00:00:00Z"),
              )
            None => assert_true(false)
          }
        }
        DestroyNotFound(_) => assert_true(false)
      }
    }
    DestroyNotFound(_) => assert_true(false)
  }

  match destroy_record(hard_schema, empty_memory_database(), "missing") {
    DestroyNotFound(same_db) => assert_eq(same_db.tables.length(), 0)
    DestroyedRecord(_, _) => assert_true(false)
  }
}
