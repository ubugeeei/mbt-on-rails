///|
/// Errors raised by a cache backend adapter.
pub(all) enum CacheAdapterError {
  CacheConnectionFailed(String)
  CacheSerializationFailed(String)
  CacheTimeout(String)
  CacheOtherError(String)
}

///|
/// Renders a cache adapter error as a CLI / diagnostic-friendly string.
pub fn cache_adapter_error_message(error : CacheAdapterError) -> String {
  match error {
    CacheConnectionFailed(detail) => "connection_failed: " + detail
    CacheSerializationFailed(detail) => "serialization_failed: " + detail
    CacheTimeout(detail) => "timeout: " + detail
    CacheOtherError(detail) => "other: " + detail
  }
}

///|
/// Outcome of a read.
pub(all) enum CacheReadOutcome {
  CacheHit(String)
  CacheMiss
  CacheReadFailed(CacheAdapterError)
}

///|
/// Outcome of a write / delete / tag-delete / close.
pub(all) enum CacheWriteOutcome {
  CacheWritten
  CacheWriteFailed(CacheAdapterError)
}

///|
/// Pluggable contract for a cache backend driver (Redis, Memcached,
/// in-process, etc.). All operations are keyed by a String; values are
/// stored as opaque strings (callers serialise to JSON / messagepack
/// before handing them in).
pub(all) struct CacheAdapter {
  name : String
  read : (String) -> CacheReadOutcome
  write : (String, String, String?) -> CacheWriteOutcome
  delete : (String) -> CacheWriteOutcome
  delete_tag : (String) -> CacheWriteOutcome
  close : () -> CacheWriteOutcome
}

///|
/// Builds a cache adapter from explicit function values.
pub fn cache_adapter(
  name : String,
  read : (String) -> CacheReadOutcome,
  write : (String, String, String?) -> CacheWriteOutcome,
  delete : (String) -> CacheWriteOutcome,
  delete_tag : (String) -> CacheWriteOutcome,
  close : () -> CacheWriteOutcome,
) -> CacheAdapter {
  { name, read, write, delete, delete_tag, close }
}

///|
/// Returns an adapter that always reports `CacheConnectionFailed`.
pub fn null_cache_adapter() -> CacheAdapter {
  let fail_read = fn(_key : String) -> CacheReadOutcome {
    CacheReadFailed(CacheConnectionFailed("null adapter is offline"))
  }
  let fail_write = fn(
    _key : String,
    _value : String,
    _expires_at : String?,
  ) -> CacheWriteOutcome {
    CacheWriteFailed(CacheConnectionFailed("null adapter is offline"))
  }
  let fail_delete = fn(_key : String) -> CacheWriteOutcome {
    CacheWriteFailed(CacheConnectionFailed("null adapter is offline"))
  }
  let close_self = fn() -> CacheWriteOutcome { CacheWritten }
  {
    name: "null",
    read: fail_read,
    write: fail_write,
    delete: fail_delete,
    delete_tag: fail_delete,
    close: close_self,
  }
}

///|
/// Returns an in-memory cache adapter backed by the framework's existing
/// `CacheStore` value, exposed through the cache-adapter contract. The
/// underlying CacheStore is held in a single-element array so callers
/// can read its final state from outside the adapter once their test is
/// done.
pub fn memory_cache_adapter(state : Array[CacheStore]) -> CacheAdapter {
  if state.is_empty() {
    state.push(cache_store("memory_cache_adapter"))
  }
  let read = fn(key : String) -> CacheReadOutcome {
    match cache_read(state[0], key, None) {
      Some(value) => CacheHit(value)
      None => CacheMiss
    }
  }
  let write = fn(
    key : String,
    value : String,
    expires_at : String?,
  ) -> CacheWriteOutcome {
    state[0] = cache_write(state[0], key, value, None, expires_at, [])
    CacheWritten
  }
  let delete = fn(key : String) -> CacheWriteOutcome {
    state[0] = cache_delete(state[0], key)
    CacheWritten
  }
  let delete_tag = fn(tag : String) -> CacheWriteOutcome {
    state[0] = cache_delete_tag(state[0], tag)
    CacheWritten
  }
  let close = fn() -> CacheWriteOutcome { CacheWritten }
  { name: "memory", read, write, delete, delete_tag, close }
}

///|
/// Reads one key through an adapter.
pub fn cache_adapter_read(
  adapter : CacheAdapter,
  key : String,
) -> CacheReadOutcome {
  (adapter.read)(key)
}

///|
/// Writes one key through an adapter.
pub fn cache_adapter_write(
  adapter : CacheAdapter,
  key : String,
  value : String,
  expires_at : String?,
) -> CacheWriteOutcome {
  (adapter.write)(key, value, expires_at)
}

///|
/// Deletes one key through an adapter.
pub fn cache_adapter_delete(
  adapter : CacheAdapter,
  key : String,
) -> CacheWriteOutcome {
  (adapter.delete)(key)
}

///|
/// Deletes everything that carries a tag.
pub fn cache_adapter_delete_tag(
  adapter : CacheAdapter,
  tag : String,
) -> CacheWriteOutcome {
  (adapter.delete_tag)(tag)
}

///|
/// Closes the adapter (releases any held connection).
pub fn cache_adapter_close(adapter : CacheAdapter) -> CacheWriteOutcome {
  (adapter.close)()
}

///|
/// One-line summary of a cache adapter for CLI / diagnostics output.
pub fn cache_adapter_summary(adapter : CacheAdapter) -> String {
  "cache_adapter name=" + adapter.name
}
