///|
/// Serializes one flat payload into a JSON object.
pub fn serialize_payload(payload : Array[(String, String)]) -> String {
  @support.entries_to_json(payload)
}

///|
/// Parses one serialized payload JSON object back into flat entries.
pub fn deserialize_payload(payload_json : String) -> Array[(String, String)]? {
  let length = payload_json.length()
  let mut index = skip_json_whitespace(payload_json, 0)
  if index >= length || json_char_at(payload_json, index) != '{' {
    return None
  }
  index += 1
  index = skip_json_whitespace(payload_json, index)
  let entries : Array[(String, String)] = []
  if index < length && json_char_at(payload_json, index) == '}' {
    return Some(entries)
  }
  while index < length {
    match parse_json_string(payload_json, index) {
      Some((key, next_key_index)) => {
        index = skip_json_whitespace(payload_json, next_key_index)
        if index >= length || json_char_at(payload_json, index) != ':' {
          return None
        }
        index = skip_json_whitespace(payload_json, index + 1)
        match parse_json_scalar(payload_json, index) {
          Some((value, next_value_index)) => {
            entries.push((key, value))
            index = skip_json_whitespace(payload_json, next_value_index)
            if index >= length {
              return None
            }
            match json_char_at(payload_json, index) {
              ',' => index = skip_json_whitespace(payload_json, index + 1)
              '}' => return Some(entries)
              _ => return None
            }
          }
          None => return None
        }
      }
      None => return None
    }
  }
  None
}

///|
/// Serializes one enqueued job into a transport-friendly envelope.
pub fn serialize_job(
  current_job : EnqueuedJob,
  adapter : JobAdapter,
) -> SerializedJob {
  let definition = job(
    name=current_job.name,
    queue=current_job.queue,
    argument_types=current_job.argument_types,
    retry_limit=current_job.retry_limit,
    unique_key=current_job.unique_key,
    failure_policies=current_job.failure_policies,
  )
  serialized_job(
    adapter~,
    definition~,
    payload_json=serialize_payload(current_job.payload),
    run_at=current_job.run_at,
    attempts=current_job.attempts,
  )
}

///|
/// Restores one enqueued job from a serialized envelope.
pub fn restore_enqueued_job(serialized : SerializedJob) -> EnqueuedJob? {
  match deserialize_payload(serialized.payload_json) {
    Some(payload) =>
      Some(
        enqueued_job(
          definition=serialized.definition,
          payload~,
          run_at=serialized.run_at,
          attempts=serialized.attempts,
        ),
      )
    None => None
  }
}

///|
/// Renders one serialized job envelope as JSON for storage or transport.
pub fn render_serialized_job(serialized : SerializedJob) -> String {
  "{" +
  "\"adapter\": " +
  @support.json_string(serialized.adapter.name) +
  ", \"job\": " +
  @support.json_string(serialized.definition.name) +
  ", \"queue\": " +
  @support.json_string(serialized.definition.queue) +
  ", \"payload\": " +
  serialized.payload_json +
  ", \"run_at\": " +
  @support.json_string(serialized.run_at) +
  ", \"attempts\": " +
  serialized.attempts.to_string() +
  ", \"retry_limit\": " +
  serialized.definition.retry_limit.to_string() +
  ", \"unique_key\": " +
  (match serialized.definition.unique_key {
    Some(value) => @support.json_string(value)
    None => "null"
  }) +
  "}"
}

///|
/// Renders one serialized job in a CLI-friendly summary format.
pub fn serialized_job_summary(serialized : SerializedJob) -> String {
  "serialized " +
  serialized.definition.name +
  " via " +
  serialized.adapter.name +
  " queue=" +
  serialized.definition.queue +
  " attempts=" +
  serialized.attempts.to_string() +
  " run_at=" +
  (if serialized.run_at.length() == 0 { "now" } else { serialized.run_at }) +
  " payload=" +
  serialized.payload_json
}

///|
fn skip_json_whitespace(source : String, start : Int) -> Int {
  let mut index = start
  while index < source.length() {
    let ch = json_char_at(source, index)
    if ch == ' ' || ch == '\n' || ch == '\r' || ch == '\t' {
      index += 1
    } else {
      return index
    }
  }
  index
}

///|
fn parse_json_string(source : String, start : Int) -> (String, Int)? {
  if start >= source.length() || json_char_at(source, start) != '"' {
    return None
  }
  let builder = StringBuilder::new()
  let mut index = start + 1
  while index < source.length() {
    let ch = json_char_at(source, index)
    if ch == '"' {
      return Some((builder.to_string(), index + 1))
    }
    if ch == '\\' {
      if index + 1 >= source.length() {
        return None
      }
      let escaped = json_char_at(source, index + 1)
      match escaped {
        '"' => builder.write_char('"')
        '\\' => builder.write_char('\\')
        'n' => builder.write_char('\n')
        'r' => builder.write_char('\r')
        't' => builder.write_char('\t')
        _ => return None
      }
      index += 2
    } else {
      builder.write_char(ch)
      index += 1
    }
  }
  None
}

///|
fn parse_json_scalar(source : String, start : Int) -> (String, Int)? {
  if start >= source.length() {
    return None
  }
  if json_char_at(source, start) == '"' {
    return parse_json_string(source, start)
  }
  let builder = StringBuilder::new()
  let mut index = start
  while index < source.length() {
    let ch = json_char_at(source, index)
    if ch == ',' || ch == '}' {
      let value = builder.to_string().trim().to_string()
      if value.length() == 0 {
        return None
      }
      return Some((value, index))
    }
    builder.write_char(ch)
    index += 1
  }
  None
}

///|
fn json_char_at(source : String, index : Int) -> Char {
  source.unsafe_get(index).unsafe_to_char()
}
