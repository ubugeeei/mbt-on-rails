# In-memory relation executor: unsupported query features

## Background
`execute` on the in-memory ActiveRecord adapter still rejects several relation shapes.
This limits fidelity of tests that rely on `group_by`, `having`, `joins`, and raw predicates.

## Current unsupported features
- [ ] `join_relation(...)` returns `RelationExecutionIssue("joins", ... )`
- [ ] `group_by(...)` returns `RelationExecutionIssue("group_by", ... )`
- [ ] `having_raw(...)` returns `RelationExecutionIssue("having", ... )`
- [ ] `where_raw(...)` returns `RelationExecutionIssue("raw_predicate", ... )` for non-simple expressions (`=` / `!=` are now supported in-memory)

## Scope proposal
1. Introduce a phased execution plan that can evaluate grouped rows in-memory.
2. Add a minimal parser/evaluator for safe aggregate HAVING expressions.
3. Keep raw SQL opt-in and gated behind explicit adapter capability flags.
4. Add golden tests for supported/unsupported boundaries.

## This PR's first step
- [x] Treat `preload(...)` as metadata-only during in-memory execution instead of failing.
- [x] Keep returning explicit issues for genuinely non-executable features listed above.
