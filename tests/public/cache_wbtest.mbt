///|
test "cache entries expire at the boundary timestamp" {
  let store = cache_write(
    cache_store("pages"),
    "posts:index",
    "cached",
    None,
    Some("2026-03-26T12:00:00Z"),
    ["posts"],
  )

  assert_eq(
    cache_read(store, "posts:index", Some("2026-03-26T11:59:59Z")),
    Some("cached"),
  )
  assert_eq(
    cache_read(store, "posts:index", Some("2026-03-26T12:00:00Z")),
    None,
  )
  assert_eq(
    cache_read(store, "posts:index", Some("2026-03-26T12:00:01Z")),
    None,
  )
}
