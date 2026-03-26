# Part 3: Models and Migrations

## Goal

Learn the data-modeling surface, the opinionated migration DSL, and the safe phased pattern this repository recommends.

## Key Files

- [`../../src/active_record/schema.mbt`](../../src/active_record/schema.mbt)
- [`../../src/active_record/behavior.mbt`](../../src/active_record/behavior.mbt)
- [`../../src/migration/migration.mbt`](../../src/migration/migration.mbt)
- [`../../examples/orm_migration/main.mbt`](../../examples/orm_migration/main.mbt)

## Define A Model

Models are declared with labeled arguments and column builders:

```moonbit
let post = model(
  name="Post",
  table="posts",
  columns=[
    string_column("title"),
    string_column("slug").indexed().unique(),
    text_column("body"),
  ],
)
```

That schema is already close to the migration surface:

- columns come from `string_column`, `text_column`, `boolean_column`, `references_column`, and friends
- shape changes can later reuse the same column builders in `migration_plan(...)`
- associations and validations stay on the model side, while DDL stays in the migration side

## Add Associations and Defaults

The ORM surface currently supports:

- `belongs_to`
- `has_one`
- `has_many`
- `has_and_belongs_to_many`
- `with_default`
- `nullable`

This is intentionally smaller than Rails, but the shape is already there.

## Generate Create-Table SQL

You can derive migration steps from model definitions:

```moonbit
let create_posts = migration_from_model(
  "20260323010101",
  "create_posts",
  post,
)
```

From there:

- `migration_up_sql(...)`
- `migration_down_sql(...)`
- `schema_sql(...)`

This is the shortest path when you are introducing a brand new table.

## Build A Phased Migration Plan

For existing tables, the more interesting API is `migration_plan(...)` plus chainable steps:

```moonbit
let backfill_published = migration_plan(
  "20260326030101",
  "backfill_post_published",
)
  .add_column("posts", nullable(boolean_column("published")))
  .change_default("posts", "published", None, Some("false"))
  .change_null("posts", "published", false, backfill_value=Some("false"))
  .add_index_concurrently("posts", "published", false)
```

This style is intentionally opinionated:

- add the column as nullable first
- add a default separately
- backfill before tightening `NOT NULL`
- use concurrent index creation for production-style deploys

The DSL also includes:

- `add_reference(...)`
- `add_timestamps(...)`
- `remove_index_concurrently(...)`
- `rename_column(...)`
- `rename_table(...)`
- `execute_sql(...)`
- `reversible(...)`

## Check Migration Safety

The migration module now ships with a Strong Migrations-style analyzer:

```moonbit
let summary = migration_safety_summary(backfill_published)
let issues = analyze_migration(backfill_published)
let safe = migration_safe(backfill_published)
```

The analyzer classifies steps into:

- `Safe`
- `Review`
- `Dangerous`

Typical examples:

- `add_column(..., boolean_column("published"))` is flagged because it is `NOT NULL` from the start
- `remove_column(...)` is flagged as destructive
- `execute_sql(...)` is flagged for manual review
- phased nullable/backfill/concurrent-index plans can stay `Safe`

## Where To See It Running

- [`../../examples/orm_migration/main.mbt`](../../examples/orm_migration/main.mbt)
- [`../../tests/public/core_wbtest.mbt`](../../tests/public/core_wbtest.mbt)
- [`../../examples/orm_migration/main_wbtest.mbt`](../../examples/orm_migration/main_wbtest.mbt)
- [`../../tests/public/relation_render_wbtest.mbt`](../../tests/public/relation_render_wbtest.mbt)

## Exercise

- Add a `published` flag column to a toy `Post` model
- First write it as a one-shot `add_column("posts", boolean_column("published"))`
- Then rewrite it as a phased `migration_plan(...)`
- Compare `migration_safety_summary(...)` for both versions

## Next

Continue to [Part 4: Validations and Queries](part_04_validations_and_queries.md).
