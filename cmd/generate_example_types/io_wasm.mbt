///|
fn ensure_supported_target() -> Unit {
  fatal_cli("unsupported target; run with --target native")
}

///|
fn discover_templates(_views_dir : String) -> Array[String] {
  fail_unsupported_target()
}

///|
fn read_text_file(_path : String) -> String {
  fail_unsupported_target()
}

///|
fn write_text_file(_path : String, _content : String) -> Unit {
  fail_unsupported_target()
}

///|
fn[T] fail_unsupported_target() -> T {
  fatal_cli("unsupported target; run with --target native")
}

///|
fn[T] fatal_cli(message : String) -> T {
  ignore(@utf8.encode("").length())
  println("generate_example_types: " + message)
  abort("generate_example_types: " + message)
}
