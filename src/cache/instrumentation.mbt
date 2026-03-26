///|
/// Reads one cache entry and records a Rails-style cache read event.
pub fn cache_read_with_notifications(
  store~ : CacheStore,
  key~ : String,
  now~ : String?,
  notifications~ : @support.Notifications,
) -> (String?, @support.Notifications) {
  let value = cache_read(store, key, now)
  let hit = match value {
    Some(_) => "true"
    None => "false"
  }
  let updated = notifications.instrument(
    name="cache_read.active_support",
    payload=[
      ("store", store.store_name),
      ("key", key),
      ("hit", hit),
    ],
  )
  (value, updated)
}

///|
/// Writes one cache entry and records a Rails-style cache write event.
pub fn cache_write_with_notifications(
  store~ : CacheStore,
  key~ : String,
  value~ : String,
  version~ : String?,
  expires_at~ : String?,
  tags~ : Array[String],
  notifications~ : @support.Notifications,
) -> (CacheStore, @support.Notifications) {
  let updated_store = cache_write(store, key, value, version, expires_at, tags)
  let updated = notifications.instrument(
    name="cache_write.active_support",
    payload=[
      ("store", store.store_name),
      ("key", key),
      ("tag_count", tags.length().to_string()),
    ],
  )
  (updated_store, updated)
}

///|
/// Reads through the cache and records read/generate/write events as needed.
pub fn cache_fetch_with_notifications(
  store~ : CacheStore,
  key~ : String,
  fallback~ : String,
  version~ : String?,
  expires_at~ : String?,
  tags~ : Array[String],
  now~ : String?,
  notifications~ : @support.Notifications,
) -> (CacheFetchResult, @support.Notifications) {
  let (cached, after_read) = cache_read_with_notifications(
    store=store,
    key=key,
    now=now,
    notifications=notifications,
  )
  match cached {
    Some(value) => ({ store, value, hit: true }, after_read)
    None => {
      let after_generate = after_read.instrument(
        name="cache_generate.active_support",
        payload=[
          ("store", store.store_name),
          ("key", key),
        ],
      )
      let (updated_store, after_write) = cache_write_with_notifications(
        store=store,
        key=key,
        value=fallback,
        version=version,
        expires_at=expires_at,
        tags=tags,
        notifications=after_generate,
      )
      ({ store: updated_store, value: fallback, hit: false }, after_write)
    }
  }
}

///|
/// Deletes one cache key and records a Rails-style delete event.
pub fn cache_delete_with_notifications(
  store~ : CacheStore,
  key~ : String,
  notifications~ : @support.Notifications,
) -> (CacheStore, @support.Notifications) {
  let updated_store = cache_delete(store, key)
  let updated = notifications.instrument(
    name="cache_delete.active_support",
    payload=[
      ("store", store.store_name),
      ("key", key),
    ],
  )
  (updated_store, updated)
}

///|
/// Deletes entries by tag and records a delete-matched style event.
pub fn cache_delete_tag_with_notifications(
  store~ : CacheStore,
  tag~ : String,
  notifications~ : @support.Notifications,
) -> (CacheStore, @support.Notifications) {
  let updated_store = cache_delete_tag(store, tag)
  let updated = notifications.instrument(
    name="cache_delete_matched.active_support",
    payload=[
      ("store", store.store_name),
      ("matcher", "tag:" + tag),
    ],
  )
  (updated_store, updated)
}
