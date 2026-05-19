///|
fn callback_schema() -> ModelSchema {
  model(
    name="Tag",
    table="tags",
    columns=[string_column("name"), string_column("state")],
    timestamps=false,
  )
}

///|
test "run_record_callbacks threads the record through each step" {
  let record0 = record("tags", [("id", "1"), ("name", "ruby"), ("state", "")])
  let promote : (Record) -> CallbackOutcome = fn(_) {
    Continue(
      record("tags", [("id", "1"), ("name", "ruby"), ("state", "promoted")]),
    )
  }
  let tag : (Record) -> CallbackOutcome = fn(record_in) {
    Continue(
      record("tags", [
        ("id", "1"),
        ("name", find_entry(record_in.fields, "name").unwrap() + "-tagged"),
        ("state", find_entry(record_in.fields, "state").unwrap()),
      ]),
    )
  }
  match run_record_callbacks([promote, tag], record0) {
    Continue(final_record) => {
      assert_true(
        find_entry(final_record.fields, "name") == Some("ruby-tagged"),
      )
      assert_true(find_entry(final_record.fields, "state") == Some("promoted"))
    }
    Halt(_) => assert_true(false)
  }
}

///|
test "run_record_callbacks halts on the first Halt and skips the rest" {
  let record0 = record("tags", [("id", "1"), ("name", "x"), ("state", "")])
  let halt_step : (Record) -> CallbackOutcome = fn(_) { Halt("nope") }
  let should_not_run : (Record) -> CallbackOutcome = fn(_) {
    Continue(
      record("tags", [("id", "1"), ("name", "should-not-appear"), ("state", "")]),
    )
  }
  match run_record_callbacks([halt_step, should_not_run], record0) {
    Continue(_) => assert_true(false)
    Halt(reason) => assert_eq(reason, "nope")
  }
}

///|
test "save_record_with_callbacks runs before_save then after_save" {
  let schema = callback_schema()
  let db = empty_memory_database()
  let starting = record("tags", [
    ("id", "10"),
    ("name", "draft"),
    ("state", "raw"),
  ])
  let before_save : (Record) -> CallbackOutcome = fn(record_in) {
    Continue(
      record("tags", [
        ("id", find_entry(record_in.fields, "id").unwrap()),
        ("name", find_entry(record_in.fields, "name").unwrap()),
        ("state", "pre"),
      ]),
    )
  }
  let after_save : (Record) -> CallbackOutcome = fn(record_in) {
    Continue(
      record("tags", [
        ("id", find_entry(record_in.fields, "id").unwrap()),
        ("name", find_entry(record_in.fields, "name").unwrap() + "!"),
        ("state", find_entry(record_in.fields, "state").unwrap() + "/post"),
      ]),
    )
  }
  match
    save_record_with_callbacks(schema, db, starting, [before_save], [after_save]) {
    SavedAfterCallbacks(updated_db, finalized) => {
      assert_true(find_entry(finalized.fields, "name") == Some("draft!"))
      assert_true(find_entry(finalized.fields, "state") == Some("pre/post"))
      match find_record_by_primary_key(schema, updated_db, "10") {
        Some(persisted) =>
          assert_true(find_entry(persisted.fields, "state") == Some("pre"))
        None => assert_true(false)
      }
    }
    SaveValidationFailed(_) => assert_true(false)
    SaveCallbackHalted(_) => assert_true(false)
  }
}

///|
test "save_record_with_callbacks surfaces halts as SaveCallbackHalted" {
  let schema = callback_schema()
  let halt_step : (Record) -> CallbackOutcome = fn(_) { Halt("blocked") }
  let noop : (Record) -> CallbackOutcome = fn(record_in) { Continue(record_in) }
  let outcome = save_record_with_callbacks(
    schema,
    empty_memory_database(),
    record("tags", [("id", "1"), ("name", "x"), ("state", "")]),
    [halt_step],
    [noop],
  )
  match outcome {
    SaveCallbackHalted(reason) => assert_eq(reason, "blocked")
    SavedAfterCallbacks(_, _) => assert_true(false)
    SaveValidationFailed(_) => assert_true(false)
  }
}

///|
test "destroy_record_with_callbacks runs before/after around a real destroy" {
  let schema = callback_schema()
  let starting = record("tags", [
    ("id", "1"),
    ("name", "ruby"),
    ("state", "active"),
  ])
  let db = insert_record(empty_memory_database(), starting)
  let mut before_calls = 0
  let mut after_calls = 0
  let before_destroy : (Record) -> CallbackOutcome = fn(record_in) {
    before_calls = before_calls + 1
    Continue(record_in)
  }
  let after_destroy : (Record) -> CallbackOutcome = fn(record_in) {
    after_calls = after_calls + 1
    Continue(record_in)
  }
  let outcome = destroy_record_with_callbacks(
    schema,
    db,
    "1",
    [before_destroy],
    [after_destroy],
  )
  match outcome {
    DestroyedAfterCallbacks(updated_db, _) => {
      assert_eq(before_calls, 1)
      assert_eq(after_calls, 1)
      assert_true(find_record_by_primary_key(schema, updated_db, "1") is None)
    }
    DestroyTargetMissing(_) => assert_true(false)
    DestroyCallbackHalted(_) => assert_true(false)
  }
}

///|
test "destroy_record_with_callbacks halts when before_destroy bails out" {
  let schema = callback_schema()
  let starting = record("tags", [
    ("id", "1"),
    ("name", "ruby"),
    ("state", "active"),
  ])
  let db = insert_record(empty_memory_database(), starting)
  let halt : (Record) -> CallbackOutcome = fn(_) { Halt("not-yet") }
  let after : (Record) -> CallbackOutcome = fn(record_in) {
    Continue(record_in)
  }
  let outcome = destroy_record_with_callbacks(schema, db, "1", [halt], [after])
  match outcome {
    DestroyCallbackHalted(reason) => {
      assert_eq(reason, "not-yet")
      match find_record_by_primary_key(schema, db, "1") {
        Some(_) => assert_true(true)
        None => assert_true(false)
      }
    }
    DestroyedAfterCallbacks(_, _) => assert_true(false)
    DestroyTargetMissing(_) => assert_true(false)
  }
}
