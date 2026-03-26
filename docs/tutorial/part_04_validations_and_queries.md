# Part 4: Validations and Queries

## Goal

Understand validations, in-memory persistence, and the relation builder.

## Key Files

- [`../../src/active_record/relation.mbt`](../../src/active_record/relation.mbt)
- [`../../src/active_record/sql.mbt`](../../src/active_record/sql.mbt)
- [`../../src/active_record/memory.mbt`](../../src/active_record/memory.mbt)
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
- `save_record(...)`
- `validate_record(...)`
- `begin_transaction(...)`
- `create_savepoint(...)`
- `transaction_save(...)`

Dirty tracking is also explicit:

- `dirty_record(...)`
- `dirty_new_record(...)`
- `record.track_changes(...)`
- `.changed_fields()`
- `.attribute_was(...)`
- `.clear_changes_information()`

This makes the tutorial runnable without needing a real database adapter.

Example:

```moonbit
let dirty = original_record.track_changes(updated_record)
let tx = empty_memory_database()
  .begin_transaction()
  .insert(updated_record)
  .savepoint("after_insert")
```

## Rails Gap

- no adapter-backed query execution yet
- no callback chain execution yet
- no database adapter abstraction yet

See [`../rails_alignment.md`](../rails_alignment.md).

## Exercise

- Create an invalid record with a duplicate slug
- Run `validate_record(...)`
- Confirm the error list is data, not exceptions

## Next

Continue to [Part 5: Authentication and Authorization](part_05_authentication_and_authorization.md).
