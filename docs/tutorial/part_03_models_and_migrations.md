# Part 3: Models and Migrations

## Goal

Learn the data-modeling surface and how schema changes are represented.

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

## Add Associations and Defaults

The ORM surface currently supports:

- `belongs_to`
- `has_one`
- `has_many`
- `has_and_belongs_to_many`
- `with_default`
- `nullable`

This is intentionally smaller than Rails, but the shape is already there.

## Generate Migration SQL

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

## Where To See It Running

- [`../../examples/orm_migration/main.mbt`](../../examples/orm_migration/main.mbt)
- [`../../tests/public/core_wbtest.mbt`](../../tests/public/core_wbtest.mbt)
- [`../../tests/public/relation_render_wbtest.mbt`](../../tests/public/relation_render_wbtest.mbt)

## Exercise

- Add a `published` flag column to a toy `Post` model
- Generate migration SQL
- Check how the resulting SQL differs from a plain string/text-only model

## Next

Continue to [Part 4: Validations and Queries](part_04_validations_and_queries.md).
