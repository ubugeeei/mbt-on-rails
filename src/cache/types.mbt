///|
/// Represents one cached value together with metadata.
pub struct CacheEntry {
  key : String
  value : String
  version : String?
  expires_at : String?
  tags : Array[String]
}

///|
/// Stores cached values under one namespace.
pub struct CacheStore {
  store_name : String
  entries : Array[CacheEntry]
}

///|
/// Reports whether a cache lookup was a hit or required recomputation.
pub struct CacheFetchResult {
  store : CacheStore
  value : String
  hit : Bool
}

///|
/// Builds an empty cache store.
pub fn cache_store(store_name : String) -> CacheStore {
  { store_name, entries: [] }
}

///|
/// Builds a namespaced cache key from path-like segments.
pub fn cache_key(parts : Array[String]) -> String {
  parts.join(":")
}
