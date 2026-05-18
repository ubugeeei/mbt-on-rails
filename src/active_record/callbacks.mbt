///|
/// Outcome of running a callback against a record.
///
/// `Continue(next)` lets the pipeline progress with the (possibly
/// mutated) record. `Halt(reason)` aborts the surrounding persistence
/// operation; callers surface the reason through the typed outcome
/// returned by `save_record_with_callbacks` /
/// `destroy_record_with_callbacks`.
pub(all) enum CallbackOutcome {
  Continue(Record)
  Halt(String)
}

///|
/// Runs a sequence of record callbacks, threading the record through
/// each step. The first `Halt` short-circuits the rest and is returned
/// verbatim.
pub fn run_record_callbacks(
  callbacks : Array[(Record) -> CallbackOutcome],
  record : Record,
) -> CallbackOutcome {
  let mut current = record
  for callback in callbacks {
    match callback(current) {
      Continue(next) => current = next
      Halt(reason) => return Halt(reason)
    }
  }
  Continue(current)
}

///|
/// Outcome of `save_record_with_callbacks`.
pub(all) enum SaveWithCallbacksOutcome {
  SavedAfterCallbacks(MemoryDatabase, Record)
  SaveValidationFailed(ValidationErrors)
  SaveCallbackHalted(String)
}

///|
/// Runs the `before_save` callbacks, persists with `save_record`, and
/// then runs the `after_save` callbacks. A halting callback returns
/// `SaveCallbackHalted`; underlying validation errors surface as
/// `SaveValidationFailed`. Successful runs return the database snapshot
/// produced by `save_record` and the record threaded through the
/// `after_save` callbacks.
pub fn save_record_with_callbacks(
  schema : ModelSchema,
  db : MemoryDatabase,
  record : Record,
  before_save : Array[(Record) -> CallbackOutcome],
  after_save : Array[(Record) -> CallbackOutcome],
) -> SaveWithCallbacksOutcome {
  let pre = match run_record_callbacks(before_save, record) {
    Continue(next) => next
    Halt(reason) => return SaveCallbackHalted(reason)
  }
  match save_record(schema, db, pre) {
    Saved(updated_db, saved) =>
      match run_record_callbacks(after_save, saved) {
        Continue(finalized) => SavedAfterCallbacks(updated_db, finalized)
        Halt(reason) => SaveCallbackHalted(reason)
      }
    ValidationFailed(errors) => SaveValidationFailed(errors)
  }
}

///|
/// Outcome of `destroy_record_with_callbacks`.
pub(all) enum DestroyWithCallbacksOutcome {
  DestroyedAfterCallbacks(MemoryDatabase, Record)
  DestroyTargetMissing(MemoryDatabase)
  DestroyCallbackHalted(String)
}

///|
/// Runs `before_destroy`, performs the destroy via `destroy_record`,
/// and then runs `after_destroy` on the row that was removed (or
/// tombstoned, for soft-delete models). Missing records yield
/// `DestroyTargetMissing` without invoking any callback.
pub fn destroy_record_with_callbacks(
  schema : ModelSchema,
  db : MemoryDatabase,
  primary_key_value : String,
  before_destroy : Array[(Record) -> CallbackOutcome],
  after_destroy : Array[(Record) -> CallbackOutcome],
  deleted_at? : String? = None,
) -> DestroyWithCallbacksOutcome {
  match find_record_by_primary_key(schema, db, primary_key_value) {
    None => DestroyTargetMissing(db)
    Some(existing) =>
      match run_record_callbacks(before_destroy, existing) {
        Halt(reason) => DestroyCallbackHalted(reason)
        Continue(_) =>
          match destroy_record(schema, db, primary_key_value, deleted_at~) {
            DestroyNotFound(updated_db) => DestroyTargetMissing(updated_db)
            DestroyedRecord(updated_db, removed) =>
              match run_record_callbacks(after_destroy, removed) {
                Continue(final_record) =>
                  DestroyedAfterCallbacks(updated_db, final_record)
                Halt(reason) => DestroyCallbackHalted(reason)
              }
          }
      }
  }
}
