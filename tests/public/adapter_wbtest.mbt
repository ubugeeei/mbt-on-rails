///|
test "null_database_adapter reports connection_failed for every call" {
  let adapter = null_database_adapter()
  assert_eq(adapter_summary(adapter), "adapter name=null")
  match adapter_execute(adapter, "SELECT 1", []) {
    QuerySucceeded(_) => assert_true(false)
    QueryFailed(error) =>
      assert_eq(
        adapter_error_message(error),
        "connection_failed: null adapter is offline",
      )
  }
  match adapter_begin(adapter) {
    TransactionStarted(_) => assert_true(false)
    TransactionBeginFailed(error) =>
      assert_eq(
        adapter_error_message(error),
        "connection_failed: null adapter is offline",
      )
  }
}

///|
test "adapter_commit and adapter_rollback reject handles from another adapter" {
  let adapter = null_database_adapter()
  let foreign : TxHandle = { id: "tx-1", adapter_name: "elsewhere" }
  match adapter_commit(adapter, foreign) {
    TransactionClosed => assert_true(false)
    TransactionCloseFailed(error) =>
      assert_true(
        adapter_error_message(error).has_prefix(
          "other: transaction handle from elsewhere",
        ),
      )
  }
  match adapter_rollback(adapter, foreign) {
    TransactionClosed => assert_true(false)
    TransactionCloseFailed(error) =>
      assert_true(
        adapter_error_message(error).has_prefix(
          "other: transaction handle from elsewhere",
        ),
      )
  }
}

///|
test "adapter_error_message renders every variant for diagnostics" {
  assert_eq(
    adapter_error_message(ConnectionFailed("db down")),
    "connection_failed: db down",
  )
  assert_eq(adapter_error_message(SyntaxError("bad")), "syntax_error: bad")
  assert_eq(
    adapter_error_message(IntegrityViolation("dup pk")),
    "integrity_violation: dup pk",
  )
  assert_eq(adapter_error_message(AdapterTimeout("5s")), "timeout: 5s")
  assert_eq(adapter_error_message(OtherAdapterError("misc")), "other: misc")
}

///|
test "database_adapter composes a fake driver for round-trip tests" {
  let fake_execute = fn(
    _sql : String,
    _binds : Array[RelationBind],
  ) -> QueryOutcome {
    QuerySucceeded(query_result(["id"], [record("rows", [("id", "1")])], 1))
  }
  let fake_begin = fn() -> TransactionBeginOutcome {
    TransactionStarted({ id: "tx-fake-1", adapter_name: "fake" })
  }
  let close_ok = fn(_handle : TxHandle) -> TransactionCloseOutcome {
    TransactionClosed
  }
  let close_self = fn() -> TransactionCloseOutcome { TransactionClosed }
  let adapter = database_adapter(
    "fake", fake_execute, fake_begin, close_ok, close_ok, close_self,
  )
  assert_eq(adapter_summary(adapter), "adapter name=fake")
  match adapter_execute(adapter, "SELECT 1", []) {
    QuerySucceeded(result) => {
      assert_eq(result.columns.length(), 1)
      assert_eq(result.columns[0], "id")
      assert_eq(result.rows.length(), 1)
      assert_eq(result.affected_rows, 1)
    }
    QueryFailed(_) => assert_true(false)
  }
  match adapter_begin(adapter) {
    TransactionStarted(handle) => {
      assert_eq(handle.id, "tx-fake-1")
      match adapter_commit(adapter, handle) {
        TransactionClosed => assert_true(true)
        TransactionCloseFailed(_) => assert_true(false)
      }
      match adapter_rollback(adapter, handle) {
        TransactionClosed => assert_true(true)
        TransactionCloseFailed(_) => assert_true(false)
      }
    }
    TransactionBeginFailed(_) => assert_true(false)
  }
  match adapter_close(adapter) {
    TransactionClosed => assert_true(true)
    TransactionCloseFailed(_) => assert_true(false)
  }
}
