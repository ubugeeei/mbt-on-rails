///|
/// Writes or replaces one cache entry.
pub fn cache_write(
  store : CacheStore,
  key : String,
  value : String,
  version : String?,
  expires_at : String?,
  tags : Array[String],
) -> CacheStore {
  let entries : Array[CacheEntry] = []
  for entry in store.entries {
    if entry.key != key {
      entries.push(entry)
    }
  }
  entries.push({ key, value, version, expires_at, tags })
  { ..store, entries, }
}

///|
/// Reads one cache entry when it exists and is still fresh.
pub fn cache_read(store : CacheStore, key : String, now : String?) -> String? {
  for entry in store.entries {
    if entry.key == key && entry_fresh(entry, now) {
      return Some(entry.value)
    }
  }
  None
}

///|
/// Reads through the cache and writes the fallback value on a miss.
pub fn cache_fetch(
  store : CacheStore,
  key : String,
  fallback : String,
  version : String?,
  expires_at : String?,
  tags : Array[String],
  now : String?,
) -> CacheFetchResult {
  match cache_read(store, key, now) {
    Some(value) => { store, value, hit: true }
    None => {
      let updated = cache_write(store, key, fallback, version, expires_at, tags)
      { store: updated, value: fallback, hit: false }
    }
  }
}

///|
/// Deletes one key from the cache store.
pub fn cache_delete(store : CacheStore, key : String) -> CacheStore {
  let entries : Array[CacheEntry] = []
  for entry in store.entries {
    if entry.key != key {
      entries.push(entry)
    }
  }
  { ..store, entries, }
}

///|
/// Deletes every entry tagged with the supplied tag.
pub fn cache_delete_tag(store : CacheStore, tag : String) -> CacheStore {
  let entries : Array[CacheEntry] = []
  for entry in store.entries {
    if not(entry.tags.contains(tag)) {
      entries.push(entry)
    }
  }
  { ..store, entries, }
}

///|
/// Renders one cache namespace in a CLI-friendly format.
pub fn cache_summary(store : CacheStore) -> String {
  let lines : Array[String] = ["cache " + store.store_name]
  for entry in store.entries {
    lines.push(
      "  - " +
      entry.key +
      " tags=[" +
      entry.tags.join(", ") +
      "] value=" +
      entry.value,
    )
  }
  lines.join("\n")
}

///|
/// Returns whether an entry is still fresh at the supplied timestamp.
fn entry_fresh(entry : CacheEntry, now : String?) -> Bool {
  match entry.expires_at {
    None => true
    Some(expires_at) =>
      match now {
        None => true
        Some(current) => lexicographic_lte(current, expires_at)
      }
  }
}

///|
/// Compares two sortable timestamps without relying on platform date helpers.
fn lexicographic_lte(left : String, right : String) -> Bool {
  let left_chars = left.to_array()
  let right_chars = right.to_array()
  let limit = if left_chars.length() < right_chars.length() {
    left_chars.length()
  } else {
    right_chars.length()
  }
  for index in 0..<limit {
    if left_chars[index] < right_chars[index] {
      return true
    }
    if left_chars[index] > right_chars[index] {
      return false
    }
  }
  left_chars.length() <= right_chars.length()
}
