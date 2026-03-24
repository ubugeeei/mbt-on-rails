///|
/// Clones an array so later mutation does not affect the original value.
pub fn[T] clone_array(items : Array[T]) -> Array[T] {
  let copied : Array[T] = []
  for item in items {
    copied.push(item)
  }
  copied
}

///|
/// Concatenates two key-value entry arrays while preserving order.
pub fn append_entries(
  left : Array[(String, String)],
  right : Array[(String, String)],
) -> Array[(String, String)] {
  let entries : Array[(String, String)] = []
  for entry in left {
    entries.push(entry)
  }
  for entry in right {
    entries.push(entry)
  }
  entries
}

///|
/// Looks up the first value for a given key in an entry array.
pub fn find_entry(entries : Array[(String, String)], key : String) -> String? {
  for entry in entries {
    if entry.0 == key {
      return Some(entry.1)
    }
  }
  None
}
