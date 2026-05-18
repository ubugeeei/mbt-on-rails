///|
/// Distinguishes `.mbtv` template paths from arbitrary strings.
pub struct MbtvPath {
  value : String
} derive(Eq, Debug)

///|
/// Wraps one `.mbtv` path so APIs can avoid raw strings.
pub fn mbtv_path(value : String) -> MbtvPath {
  { value: value.trim().to_owned() }
}

///|
/// Returns the raw path string carried by this template path.
pub fn MbtvPath::as_string(self : MbtvPath) -> String {
  self.value
}
