///|
const READ_MODE : String = "rb"

///|
const WRITE_MODE : String = "wb"

///|
const SHELL_MODE : String = "r"

///|
const SEEK_SET : Int = 0

///|
const SEEK_END : Int = 2

///|
const READ_CHUNK_SIZE : Int = 4096

///|
#borrow(path, mode)
extern "c" fn fopen(path : Bytes, mode : Bytes) -> UInt64 = "fopen"

///|
extern "c" fn fclose(stream : UInt64) -> Int = "fclose"

///|
extern "c" fn fseek(stream : UInt64, offset : Int, whence : Int) -> Int = "fseek"

///|
extern "c" fn ftell(stream : UInt64) -> Int = "ftell"

///|
#borrow(buffer)
extern "c" fn fread(
  buffer : Bytes,
  size : Int,
  count : Int,
  stream : UInt64,
) -> Int = "fread"

///|
#borrow(buffer)
extern "c" fn fwrite(
  buffer : Bytes,
  size : Int,
  count : Int,
  stream : UInt64,
) -> Int = "fwrite"

///|
#borrow(command, mode)
extern "c" fn popen(command : Bytes, mode : Bytes) -> UInt64 = "popen"

///|
extern "c" fn pclose(stream : UInt64) -> Int = "pclose"

///|
extern "c" fn abort_process() -> Unit = "abort"

///|
fn discover_templates(views_dir : String) -> Array[String] {
  let command = "test -d " +
    shell_quote(views_dir) +
    " && find " +
    shell_quote(views_dir) +
    " -type f -name '*.mbtv'"
  let output = read_command_output(command)
  let templates : Array[String] = []
  for line in output.split("\n").map(fn(part) { part.to_owned() }).collect() {
    let trimmed = normalize_relative_path(line)
    if trimmed.length() > 0 {
      templates.push(trimmed)
    }
  }
  templates.sort_by((left, right) => left.compare(right))
  templates
}

///|
fn read_command_output(command : String) -> String {
  let stream = popen(c_string(command), c_string(SHELL_MODE))
  if stream == 0UL {
    fatal_io("failed to run command: " + command)
    return ""
  }
  let output = read_stream_all(stream)
  let status = pclose(stream)
  if status != 0 {
    fatal_io("command failed: " + command)
  }
  output
}

///|
fn read_text_file(path : String) -> String {
  let stream = fopen(c_string(path), c_string(READ_MODE))
  if stream == 0UL {
    fatal_io("failed to open file for reading: " + path)
    return ""
  }
  if fseek(stream, 0, SEEK_END) != 0 {
    ignore(fclose(stream))
    fatal_io("failed to seek file: " + path)
    return ""
  }
  let size = ftell(stream)
  if size < 0 {
    ignore(fclose(stream))
    fatal_io("failed to measure file: " + path)
    return ""
  }
  if fseek(stream, 0, SEEK_SET) != 0 {
    ignore(fclose(stream))
    fatal_io("failed to rewind file: " + path)
    return ""
  }
  let bytes = FixedArray::make(size, b'\x00')
  let buffer = bytes.unsafe_reinterpret_as_bytes()
  let read_count = fread(buffer, 1, size, stream)
  if read_count != size {
    ignore(fclose(stream))
    fatal_io("failed to read complete file: " + path)
    return ""
  }
  if fclose(stream) != 0 {
    fatal_io("failed to close file after reading: " + path)
    return ""
  }
  @utf8.decode_lossy(buffer)
}

///|
fn write_text_file(path : String, content : String) -> Unit {
  let stream = fopen(c_string(path), c_string(WRITE_MODE))
  if stream == 0UL {
    fatal_io("failed to open file for writing: " + path)
    return
  }
  let encoded = @utf8.encode(content)
  let write_count = fwrite(encoded, 1, encoded.length(), stream)
  if write_count != encoded.length() {
    ignore(fclose(stream))
    fatal_io("failed to write complete file: " + path)
    return
  }
  if fclose(stream) != 0 {
    fatal_io("failed to close file after writing: " + path)
  }
}

///|
fn read_stream_all(stream : UInt64) -> String {
  let builder = StringBuilder::new()
  let chunk = FixedArray::make(READ_CHUNK_SIZE, b'\x00').unsafe_reinterpret_as_bytes()
  while true {
    let read_count = fread(chunk, 1, READ_CHUNK_SIZE, stream)
    if read_count <= 0 {
      break
    }
    builder.write_stringview(@utf8.decode_lossy(chunk[0:read_count]))
    if read_count < READ_CHUNK_SIZE {
      break
    }
  }
  builder.to_string()
}

///|
fn c_string(input : String) -> Bytes {
  let encoded = @utf8.encode(input)
  let bytes = FixedArray::make(encoded.length() + 1, b'\x00')
  bytes.blit_from_bytes(0, encoded, 0, encoded.length())
  bytes.unsafe_reinterpret_as_bytes()
}

///|
fn shell_quote(input : String) -> String {
  let builder = StringBuilder::new()
  builder.write_char('\'')
  for ch in input.to_array() {
    if ch == '\'' {
      builder.write_stringview("'\"'\"'")
    } else {
      builder.write_char(ch)
    }
  }
  builder.write_char('\'')
  builder.to_string()
}

///|
fn fatal_io(message : String) -> Unit {
  println("generate_example_types: " + message)
  abort_process()
}
