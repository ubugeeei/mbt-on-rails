///|
/// Extra ORM persistence exports kept separate so the shared prelude stays split up.
pub using @mbor {
  type DestroyOutcome,
  destroy_record,
  find_record_by_primary_key,
}
