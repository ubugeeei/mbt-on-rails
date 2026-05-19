///|
test "null_cache_adapter reports connection_failed for every call" {
  let adapter = null_cache_adapter()
  assert_eq(cache_adapter_summary(adapter), "cache_adapter name=null")
  match cache_adapter_read(adapter, "k") {
    CacheHit(_) => assert_true(false)
    CacheMiss => assert_true(false)
    CacheReadFailed(error) =>
      assert_eq(
        cache_adapter_error_message(error),
        "connection_failed: null adapter is offline",
      )
  }
  match cache_adapter_write(adapter, "k", "v", None) {
    CacheWritten => assert_true(false)
    CacheWriteFailed(error) =>
      assert_eq(
        cache_adapter_error_message(error),
        "connection_failed: null adapter is offline",
      )
  }
}

///|
test "cache_adapter_error_message renders every variant" {
  assert_eq(
    cache_adapter_error_message(CacheConnectionFailed("down")),
    "connection_failed: down",
  )
  assert_eq(
    cache_adapter_error_message(CacheSerializationFailed("bad json")),
    "serialization_failed: bad json",
  )
  assert_eq(cache_adapter_error_message(CacheTimeout("5s")), "timeout: 5s")
  assert_eq(cache_adapter_error_message(CacheOtherError("misc")), "other: misc")
}

///|
test "memory_cache_adapter round-trips read / write / delete" {
  let state : Array[CacheStore] = []
  let adapter = memory_cache_adapter(state)
  match cache_adapter_read(adapter, "user:1") {
    CacheMiss => assert_true(true)
    CacheHit(_) => assert_true(false)
    CacheReadFailed(_) => assert_true(false)
  }
  match cache_adapter_write(adapter, "user:1", "alice", None) {
    CacheWritten => assert_true(true)
    CacheWriteFailed(_) => assert_true(false)
  }
  match cache_adapter_read(adapter, "user:1") {
    CacheHit(v) => assert_eq(v, "alice")
    CacheMiss => assert_true(false)
    CacheReadFailed(_) => assert_true(false)
  }
  match cache_adapter_delete(adapter, "user:1") {
    CacheWritten => assert_true(true)
    CacheWriteFailed(_) => assert_true(false)
  }
  match cache_adapter_read(adapter, "user:1") {
    CacheMiss => assert_true(true)
    CacheHit(_) => assert_true(false)
    CacheReadFailed(_) => assert_true(false)
  }
}
