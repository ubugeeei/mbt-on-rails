///|
fn compare_row_value(
  schema : ModelSchema,
  table_name : String,
  row : Record,
  source : String,
  literal : String,
) -> Int? {
  match normalized_column_name(source, table_name) {
    Some(column) =>
      match @support.find_entry(row.fields, column) {
        Some(current) =>
          Some(
            compare_optional_values(
              Some(current),
              Some(literal),
              find_column(schema, column),
            ),
          )
        None => None
      }
    None => None
  }
}

///|
fn in_list_matches(
  schema : ModelSchema,
  table_name : String,
  source : String,
  current : String,
  values : Array[String],
) -> Bool {
  let column = match normalized_column_name(source, table_name) {
    Some(column) => find_column(schema, column)
    None => None
  }
  for value in values {
    if compare_optional_values(Some(current), Some(value), column) == 0 {
      return true
    }
  }
  false
}

///|
fn record_value_for_column(
  row : Record,
  source : String,
  table_name : String,
) -> String? {
  match normalized_column_name(source, table_name) {
    Some(column) => @support.find_entry(row.fields, column)
    None => None
  }
}

///|
fn simple_select_column(source : String, table_name : String) -> String? {
  let trimmed = source.trim().to_string()
  if trimmed == "*" || trimmed == table_name + ".*" {
    return Some("*")
  }
  normalized_column_name(trimmed, table_name)
}

///|
fn normalized_column_name(source : String, table_name : String) -> String? {
  let trimmed = source.trim().to_string()
  if trimmed.contains("(") || trimmed.contains(")") || trimmed.contains(" ") {
    return None
  }
  if trimmed.has_prefix(table_name + ".") {
    return Some(
      String::unsafe_substring(
        trimmed,
        start=table_name.length() + 1,
        end=trimmed.length(),
      ),
    )
  }
  if trimmed.contains(".") {
    return None
  }
  Some(trimmed)
}

///|
fn compare_optional_values(
  left : String?,
  right : String?,
  column : Column?,
) -> Int {
  match (left, right) {
    (None, None) => 0
    (None, Some(_)) => -1
    (Some(_), None) => 1
    (Some(left), Some(right)) => compare_typed_values(left, right, column)
  }
}

///|
fn compare_typed_values(left : String, right : String, column : Column?) -> Int {
  match column {
    Some(column) =>
      match column.column_type {
        Integer => compare_integer_strings(left, right)
        References(_) => compare_integer_strings(left, right)
        Boolean => compare_boolean_strings(left, right)
        _ => left.compare(right)
      }
    None => left.compare(right)
  }
}

///|
fn compare_integer_strings(left : String, right : String) -> Int {
  match
    (
      relation_parse_integer_literal(left),
      relation_parse_integer_literal(right),
    ) {
    (Some(left), Some(right)) => left.compare(right)
    _ => left.compare(right)
  }
}

///|
fn compare_boolean_strings(left : String, right : String) -> Int {
  match
    (
      relation_parse_boolean_literal(left),
      relation_parse_boolean_literal(right),
    ) {
    (Some(left), Some(right)) =>
      if left == right {
        0
      } else if not(left) && right {
        -1
      } else {
        1
      }
    _ => left.compare(right)
  }
}

///|
fn like_matches(value : String, pattern : String) -> Bool {
  if pattern == "%" {
    return true
  }
  if pattern.has_prefix("%") && pattern.has_suffix("%") {
    return value.contains(
      String::unsafe_substring(pattern, start=1, end=pattern.length() - 1),
    )
  }
  if pattern.has_prefix("%") {
    return value.has_suffix(
      String::unsafe_substring(pattern, start=1, end=pattern.length()),
    )
  }
  if pattern.has_suffix("%") {
    return value.has_prefix(
      String::unsafe_substring(pattern, start=0, end=pattern.length() - 1),
    )
  }
  value == pattern
}

///|
fn relation_parse_integer_literal(source : String) -> Int? {
  let trimmed = source.trim().to_string()
  if trimmed.length() == 0 {
    return None
  }
  let chars = trimmed.to_array()
  let mut index = 0
  let mut negative = false
  if chars[0] == '-' {
    negative = true
    index = 1
  }
  if index >= chars.length() {
    return None
  }
  let mut value = 0
  while index < chars.length() {
    let ch = chars[index]
    if ch < '0' || ch > '9' {
      return None
    }
    value = value * 10 + (ch.to_int() - '0'.to_int())
    index += 1
  }
  Some(if negative { -value } else { value })
}

///|
fn relation_parse_boolean_literal(source : String) -> Bool? {
  match source.trim().to_string() {
    "true" => Some(true)
    "false" => Some(false)
    "1" => Some(true)
    "0" => Some(false)
    _ => None
  }
}
