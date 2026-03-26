///|
test "phased constraint migrations stay safe and render explicit validation SQL" {
  let phased = migration_plan("20260327030101", "enforce_post_integrity")
    .add_check_constraint(
      "posts",
      "posts_slug_present",
      "slug <> ''",
      validate=false,
    )
    .add_foreign_key(
      "posts",
      "author_id",
      "users",
      validate=false,
      on_delete=Some("RESTRICT"),
    )
    .validate_check_constraint("posts", "posts_slug_present")
    .validate_foreign_key("posts", "author_id", "users")

  let up_sql = migration_up_sql(phased)
  let down_sql = migration_down_sql(phased)

  assert_true(migration_safe(phased))
  assert_eq(migration_risk_level(phased).to_string(), "Safe")
  assert_true(
    up_sql.contains(
      "ALTER TABLE posts ADD CONSTRAINT posts_slug_present CHECK (slug <> '') NOT VALID",
    ),
  )
  assert_true(
    up_sql.contains(
      "ALTER TABLE posts ADD CONSTRAINT fk_posts_author_id FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE RESTRICT NOT VALID",
    ),
  )
  assert_true(
    up_sql.contains("ALTER TABLE posts VALIDATE CONSTRAINT posts_slug_present"),
  )
  assert_true(
    up_sql.contains("ALTER TABLE posts VALIDATE CONSTRAINT fk_posts_author_id"),
  )
  assert_true(
    down_sql.contains("ALTER TABLE posts DROP CONSTRAINT posts_slug_present"),
  )
  assert_true(
    down_sql.contains("ALTER TABLE posts DROP CONSTRAINT fk_posts_author_id"),
  )
}

///|
test "validated constraint adds and removals are flagged for review" {
  let reviewed = migration_plan("20260327030102", "tighten_post_constraints")
    .add_check_constraint("posts", "posts_slug_present", "slug <> ''")
    .add_foreign_key("posts", "author_id", "users", on_delete=Some("RESTRICT"))
    .remove_check_constraint(
      "posts",
      "posts_slug_present",
      expression=Some("slug <> ''"),
    )
    .remove_foreign_key(
      "posts",
      "author_id",
      "users",
      on_delete=Some("RESTRICT"),
    )

  let issues = analyze_migration(reviewed)
  let summary = migration_safety_summary(reviewed)
  let down_sql = migration_down_sql(reviewed)

  assert_eq(migration_risk_level(reviewed).to_string(), "Review")
  assert_eq(issues.length(), 4)
  assert_true(summary.contains("validated check constraint creation"))
  assert_true(summary.contains("validated foreign key creation"))
  assert_true(summary.contains("constraint removal requires review"))
  assert_true(
    down_sql.contains(
      "ALTER TABLE posts ADD CONSTRAINT posts_slug_present CHECK (slug <> '')",
    ),
  )
  assert_true(
    down_sql.contains(
      "ALTER TABLE posts ADD CONSTRAINT fk_posts_author_id FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE RESTRICT",
    ),
  )
}
