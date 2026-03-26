# Part 4: Validations and Queries

## Goal

Understand validations, in-memory persistence, and the relation builder.

## Key Files

- [`../../src/active_record/relation.mbt`](../../src/active_record/relation.mbt)
- [`../../src/active_record/sql.mbt`](../../src/active_record/sql.mbt)
- [`../../src/active_record/memory.mbt`](../../src/active_record/memory.mbt)
- [`../../src/active_record/attributes.mbt`](../../src/active_record/attributes.mbt)
- [`../../src/active_record/serialization.mbt`](../../src/active_record/serialization.mbt)
- [`../../tests/public/active_record_edges_wbtest.mbt`](../../tests/public/active_record_edges_wbtest.mbt)

## Validations

Validation rules are explicit values:

- `validates_presence`
- `validates_uniqueness`
- `validates_confirmation`
- `validates_format`
- `validates_length_min`
- `validates_length_max`
- `validates_inclusion`

Attach them with `.with_validation(...)`.

When a rule should be reused, wrap it once as a validator object:

```moonbit
let email_like = validator(
  name="email_like",
  rule=contains(pattern="@").with_message_template(
    "must include %{pattern} for %{attribute}",
  ),
)

let schema = model(
  name="Account",
  table="accounts",
  columns=[string_column("email")],
  timestamps=false,
).with_validation(validates_with(field="email", validator=email_like))
```

Message templates can interpolate details like `%{minimum}`, `%{pattern}`, `%{attribute}`, and `%{validator}`.

## Query Building

Relations are immutable builders:

- `where_eq`
- `where_like`
- `where_in`
- `order_by`
- `reorder_by`
- `reverse_order`
- `distinct_records`
- `group_by`
- `having_raw`
- `merge_relation`
- `pluck_sql`
- `exists_sql`
- `none_relation`
- `limit_to`
- `offset_by`
- `preload`
- `join_relation`

Example:

```moonbit
let relation = relation_for(post_model)
  .where_eq("author_id", "7")
  .where_like("title", "%MoonBit%")
  .order_by("created_at", descending=true)
  .limit_to(5)
```

`descending` is labeled so the call site stays readable. Omit it to get ascending order.

Render with `relation_to_sql(...)`, `pluck_sql(...)`, or `exists_sql(...)`.

Model scopes are also data:

- `scope(...)`
- `.with_scope(...)`
- `find_scope(...)`

## In-Memory Adapter

This repo ships an in-memory store for testing and examples:

- `empty_memory_database()`
- `insert_record(...)`
- `find_records(...)`
- `find_record_by_primary_key(...)`
- `save_record(...)`
- `destroy_record(...)`
- `validate_record(...)`
- `begin_transaction(...)`
- `create_savepoint(...)`
- `transaction_save(...)`
- `execute_relation(...)`

Dirty tracking is also explicit:

- `dirty_record(...)`
- `dirty_new_record(...)`
- `record.track_changes(...)`
- `.changed_fields()`
- `.attribute_was(...)`
- `.clear_changes_information()`

This makes the tutorial runnable without needing a real database adapter.
The persistence path is also less toy-like now:

- `save_record(...)` updates the existing row when the primary key is present
- partial updates merge into the persisted row instead of dropping untouched fields
- uniqueness validations ignore the record currently being updated
- `string_column(...).unique()` and other unique column metadata are enforced by the in-memory adapter even before a real database exists
- `with_default(...)` columns and `timestamps=true` are applied during persistence, so examples get schema-shaped rows without a real database
- `destroy_record(...)` removes rows or writes a `deleted_at` tombstone for soft-delete models
- `execute_relation(...)` can run the supported subset of the same `Relation` objects used by `relation_to_sql(...)`

Unsupported shapes like `where_raw(...)`, `join_relation(...)`, `group_by(...)`, `having_raw(...)`, and `preload(...)` return explicit issues instead of silently faking success.

Example:

```moonbit
let dirty = original_record.track_changes(updated_record)
let tx = empty_memory_database()
  .begin_transaction()
  .insert(updated_record)
  .savepoint("after_insert")
```

Update and destroy flow:

```moonbit
let updated = save_record(
  schema,
  db,
  record("accounts", [("id", "1"), ("state", "published")]),
)

let removed = destroy_record(schema, db, "1")
```

## Typed Attributes and Serialization

The ORM now has a schema-aware casting layer for transport boundaries:

- `cast_record(...)`
- `serialize_record_json(...)`
- `find_column(...)`
- `attribute_type_name(...)`
- `TypedRecord::to_record()`
- `TypedRecord::to_json()`
- `AttributeCastError::message()`

This is useful when a row arrives as stringly data from forms, fixtures, or adapters,
but the rest of the app wants explicit types and predictable JSON.
Method aliases such as `row.cast(schema)`, `row.serialize_json(schema)`, and `column.attribute_type_name()` keep the call sites more cohesive too.

```moonbit
let schema = model(
  name="Post",
  table="posts",
  columns=[
    string_column("title"),
    integer_column("views"),
    boolean_column("published"),
    json_column("meta"),
    references_column("author_id", "users"),
  ],
  soft_delete=true,
)

let row = record("posts", [
  ("id", "1"),
  ("title", "Launch"),
  ("views", "42"),
  ("published", "true"),
  ("meta", "{\"tags\":[\"moonbit\"]}"),
  ("author_id", "7"),
  ("created_at", "2026-03-27T00:00:00Z"),
  ("deleted_at", "null"),
])

match row.cast(schema) {
  CastedRecord(current) => println(current.to_json())
  CastRecordFailed(errors) =>
    for error in errors {
      println(error.message())
    }
}
```

`cast_record(...)` understands generated attributes too:

- the primary key such as `id`
- `created_at` / `updated_at` when `timestamps=true`
- `deleted_at` when `soft_delete=true`

That keeps example code closer to what a real adapter would hand back.

When coercion fails, the result is still data:

```moonbit
let invalid = record("posts", [
  ("views", "forty-two"),
  ("published", "maybe"),
])

match invalid.serialize_json(schema) {
  SerializedRecordJson(json) => println(json)
  SerializeRecordFailed(errors) =>
    for error in errors {
      println("- " + error.message())
    }
}
```

`attribute_type_name(...)` is also handy for generators and docs because it renders
the expected MoonBit-facing type for a schema column such as `Int`, `Bool?`, or `Json`.

## Rails Gap

- no adapter-backed query execution yet
- no callback chain execution yet
- no database adapter abstraction yet

See [`../rails_alignment.md`](../rails_alignment.md).

## Exercise

- Create an invalid record with a duplicate slug
- Run `validate_record(...)`
- Confirm the error list is data, not exceptions
- Cast a record with `created_at` and `deleted_at`
- Confirm `deleted_at = "null"` becomes `NullAttribute`

## Next

Continue to [Part 5: Authentication and Authorization](part_05_authentication_and_authorization.md).
