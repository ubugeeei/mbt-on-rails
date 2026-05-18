///|
/// Errors raised by a database adapter.
///
/// Each variant carries a human-readable message so callers can surface
/// it through their existing logging / instrumentation without needing
/// to know what concrete driver they are talking to.
pub enum AdapterError {
  ConnectionFailed(String)
  SyntaxError(String)
  IntegrityViolation(String)
  AdapterTimeout(String)
  OtherAdapterError(String)
}

///|
/// Renders one adapter error as a CLI-friendly message.
pub fn adapter_error_message(error : AdapterError) -> String {
  match error {
    ConnectionFailed(detail) => "connection_failed: " + detail
    SyntaxError(detail) => "syntax_error: " + detail
    IntegrityViolation(detail) => "integrity_violation: " + detail
    AdapterTimeout(detail) => "timeout: " + detail
    OtherAdapterError(detail) => "other: " + detail
  }
}

///|
/// Result of a successful query.
pub struct QueryResult {
  columns : Array[String]
  rows : Array[Record]
  affected_rows : Int
  last_insert_id : String?
}

///|
/// Builds a `QueryResult` from its components.
pub fn query_result(
  columns : Array[String],
  rows : Array[Record],
  affected_rows : Int,
  last_insert_id? : String? = None,
) -> QueryResult {
  { columns, rows, affected_rows, last_insert_id }
}

///|
/// Outcome of an `execute` call.
pub enum QueryOutcome {
  QuerySucceeded(QueryResult)
  QueryFailed(AdapterError)
}

///|
/// Opaque-ish handle returned by `begin` and consumed by
/// `commit` / `rollback`. The `id` lets adapters reuse the handle
/// across calls; `adapter_name` is the name of the originating
/// adapter, so a handle accidentally passed to the wrong adapter
/// can be rejected cleanly.
pub struct TxHandle {
  id : String
  adapter_name : String
}

///|
/// Builds a transaction handle. Drivers usually call this when they
/// open a connection-level transaction so the handle can later be
/// matched against the originating adapter in `adapter_commit` /
/// `adapter_rollback`.
pub fn tx_handle(id : String, adapter_name : String) -> TxHandle {
  { id, adapter_name }
}

///|
/// Outcome of `begin`.
pub enum TransactionBeginOutcome {
  TransactionStarted(TxHandle)
  TransactionBeginFailed(AdapterError)
}

///|
/// Outcome of `commit` / `rollback` / `close`.
pub enum TransactionCloseOutcome {
  TransactionClosed
  TransactionCloseFailed(AdapterError)
}

///|
/// A pluggable contract for a real or simulated database.
///
/// All concrete drivers — in-memory, SQLite, Postgres, etc. — produce
/// a value of this shape so the rest of the framework can talk to them
/// uniformly. The function-valued fields let callers compose adapters
/// at construction time (decorate with logging, swap in a fake during
/// tests, etc.) without needing trait dispatch.
pub struct DatabaseAdapter {
  name : String
  execute : (String, Array[RelationBind]) -> QueryOutcome
  begin : () -> TransactionBeginOutcome
  commit : (TxHandle) -> TransactionCloseOutcome
  rollback : (TxHandle) -> TransactionCloseOutcome
  close : () -> TransactionCloseOutcome
}

///|
/// Builds a `DatabaseAdapter` from explicit function values.
pub fn database_adapter(
  name : String,
  execute : (String, Array[RelationBind]) -> QueryOutcome,
  begin : () -> TransactionBeginOutcome,
  commit : (TxHandle) -> TransactionCloseOutcome,
  rollback : (TxHandle) -> TransactionCloseOutcome,
  close : () -> TransactionCloseOutcome,
) -> DatabaseAdapter {
  { name, execute, begin, commit, rollback, close }
}

///|
/// Returns an adapter that always reports `ConnectionFailed`.
///
/// Useful as a placeholder during wiring and in tests that want to
/// verify the surrounding orchestration handles errors correctly
/// without standing up a real driver.
pub fn null_database_adapter() -> DatabaseAdapter {
  let fail_query = fn(_sql : String, _binds : Array[RelationBind]) -> QueryOutcome {
    QueryFailed(ConnectionFailed("null adapter is offline"))
  }
  let fail_begin = fn() -> TransactionBeginOutcome {
    TransactionBeginFailed(ConnectionFailed("null adapter is offline"))
  }
  let fail_close = fn(_handle : TxHandle) -> TransactionCloseOutcome {
    TransactionCloseFailed(ConnectionFailed("null adapter is offline"))
  }
  let close_self = fn() -> TransactionCloseOutcome { TransactionClosed }
  {
    name: "null",
    execute: fail_query,
    begin: fail_begin,
    commit: fail_close,
    rollback: fail_close,
    close: close_self,
  }
}

///|
/// Issues an `execute` against an adapter.
pub fn adapter_execute(
  adapter : DatabaseAdapter,
  sql : String,
  binds : Array[RelationBind],
) -> QueryOutcome {
  (adapter.execute)(sql, binds)
}

///|
/// Begins a transaction on an adapter.
pub fn adapter_begin(adapter : DatabaseAdapter) -> TransactionBeginOutcome {
  (adapter.begin)()
}

///|
/// Commits a transaction handle through its originating adapter.
pub fn adapter_commit(
  adapter : DatabaseAdapter,
  handle : TxHandle,
) -> TransactionCloseOutcome {
  if handle.adapter_name != adapter.name {
    return TransactionCloseFailed(
      OtherAdapterError(
        "transaction handle from " +
        handle.adapter_name +
        " cannot be used with adapter " +
        adapter.name,
      ),
    )
  }
  (adapter.commit)(handle)
}

///|
/// Rolls a transaction handle back through its originating adapter.
pub fn adapter_rollback(
  adapter : DatabaseAdapter,
  handle : TxHandle,
) -> TransactionCloseOutcome {
  if handle.adapter_name != adapter.name {
    return TransactionCloseFailed(
      OtherAdapterError(
        "transaction handle from " +
        handle.adapter_name +
        " cannot be used with adapter " +
        adapter.name,
      ),
    )
  }
  (adapter.rollback)(handle)
}

///|
/// Closes an adapter.
pub fn adapter_close(adapter : DatabaseAdapter) -> TransactionCloseOutcome {
  (adapter.close)()
}

///|
/// One-line summary of an adapter for CLI / diagnostics output.
pub fn adapter_summary(adapter : DatabaseAdapter) -> String {
  "adapter name=" + adapter.name
}
