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

Render with `relation_to_sql(...)`.

## In-Memory Adapter

This repo ships an in-memory store for testing and examples:

- `empty_memory_database()`
- `insert_record(...)`
- `find_records(...)`
- `save_record(...)`
- `validate_record(...)`

This makes the tutorial runnable without needing a real database adapter.

## Rails Gap

This is one of the largest open gaps versus Rails:

- no transaction layer yet
- no dirty tracking yet
- no full query interface yet
- no callback chain execution yet

See [`../rails_alignment.md`](../rails_alignment.md).

## Exercise

- Create an invalid record with a duplicate slug
- Run `validate_record(...)`
- Confirm the error list is data, not exceptions

## Next

Continue to [Part 5: Authentication and Authorization](part_05_authentication_and_authorization.md).
