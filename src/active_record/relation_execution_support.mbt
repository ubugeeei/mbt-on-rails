///|
fn relation_rows_for_table(
  db : MemoryDatabase,
  table_name : String,
) -> Array[Record] {
  for table in db.tables {
    if table.name == table_name {
      return @support.clone_array(table.rows)
    }
  }
  []
}

///|
fn apply_relation_to_rows(
  schema : ModelSchema,
  relation : Relation,
  rows : Array[Record],
) -> Array[Record] {
  let filtered : Array[Record] = []
  for row in rows {
    if row_matches_relation(schema, relation, row) {
      filtered.push(row)
    }
  }
  if not(relation.orderings.is_empty()) {
    filtered.sort_by(fn(left, right) {
      compare_rows_for_order(
        schema,
        relation.table,
        left,
        right,
        relation.orderings,
      )
    })
  }
  let projected = project_relation_rows(relation, filtered)
  let visible = if relation.distinct {
    distinct_relation_rows(projected)
  } else {
    projected
  }
  window_relation_rows(visible, relation.offset, relation.limit)
}

///|
fn row_matches_relation(
  schema : ModelSchema,
  relation : Relation,
  row : Record,
) -> Bool {
  for predicate in relation.predicates {
    if not(row_matches_predicate(schema, relation.table, row, predicate)) {
      return false
    }
  }
  true
}

///|
fn row_matches_predicate(
  schema : ModelSchema,
  table_name : String,
  row : Record,
  predicate : Predicate,
) -> Bool {
  match predicate {
    Eq(column, value) =>
      compare_row_value(schema, table_name, row, column, value) == Some(0)
    NotEq(column, value) =>
      compare_row_value(schema, table_name, row, column, value) != Some(0)
    Like(column, value) =>
      match record_value_for_column(row, column, table_name) {
        Some(current) => like_matches(current, value)
        None => false
      }
    Gt(column, value) =>
      match compare_row_value(schema, table_name, row, column, value) {
        Some(result) => result > 0
        None => false
      }
    Lt(column, value) =>
      match compare_row_value(schema, table_name, row, column, value) {
        Some(result) => result < 0
        None => false
      }
    InList(column, values) =>
      match record_value_for_column(row, column, table_name) {
        Some(current) =>
          in_list_matches(schema, table_name, column, current, values)
        None => false
      }
    Raw(sql) => evaluate_raw_predicate(schema, table_name, row, sql)
  }
}

///|
fn evaluate_raw_predicate(
  schema : ModelSchema,
  table_name : String,
  row : Record,
  sql : String,
) -> Bool {
  match parse_simple_raw_predicate(sql) {
    Some((column, operator, value)) =>
      match compare_row_value(schema, table_name, row, column, value) {
        Some(result) => if operator == "=" { result == 0 } else { result != 0 }
        None => false
      }
    None => false
  }
}

///|
fn parse_simple_raw_predicate(sql : String) -> (String, String, String)? {
  if sql.contains("!=") {
    return parse_simple_raw_predicate_with_operator(sql, "!=")
  }
  if sql.contains("<>") {
    return parse_simple_raw_predicate_with_operator(sql, "<>")
  }
  if sql.contains("=") {
    return parse_simple_raw_predicate_with_operator(sql, "=")
  }
  None
}

///|
fn parse_simple_raw_predicate_with_operator(
  sql : String,
  operator : String,
) -> (String, String, String)? {
  let parts = sql.split(operator).map(fn(part) { part.to_string() }).collect()
  if parts.length() != 2 {
    return None
  }
  let column = parts[0].trim().to_string()
  if column.length() == 0 {
    return None
  }
  let raw_value = parts[1].trim().to_string()
  if raw_value.length() == 0 {
    return None
  }
  let normalized = normalize_raw_literal(raw_value)
  Some((column, if operator == "=" { "=" } else { "!=" }, normalized))
}

///|
fn normalize_raw_literal(value : String) -> String {
  let trimmed = value.trim().to_string()
  if trimmed.length() >= 2 && trimmed.has_prefix("'") && trimmed.has_suffix("'") {
    return String::unsafe_substring(trimmed, start=1, end=trimmed.length() - 1)
  }
  match ascii_lowercase_literal(trimmed) {
    "true" => "true"
    "false" => "false"
    _ => trimmed
  }
}

///|
fn ascii_lowercase_literal(source : String) -> String {
  let builder = StringBuilder::new()
  for ch in source {
    if ch >= 'A' && ch <= 'Z' {
      match (ch.to_int() + 32).to_char() {
        Some(lower) => builder.write_char(lower)
        None => builder.write_char(ch)
      }
    } else {
      builder.write_char(ch)
    }
  }
  builder.to_string()
}

///|
fn project_relation_rows(
  relation : Relation,
  rows : Array[Record],
) -> Array[Record] {
  if relation.selects == ["*"] || relation.selects == [relation.table + ".*"] {
    return rows
  }
  let projected : Array[Record] = []
  for row in rows {
    let fields : Array[(String, String)] = []
    for select in relation.selects {
      match simple_select_column(select, relation.table) {
        Some("*") => return rows
        Some(column) =>
          match @support.find_entry(row.fields, column) {
            Some(value) => fields.push((column, value))
            None => ()
          }
        None => ()
      }
    }
    projected.push(record(row.table, fields))
  }
  projected
}

///|
fn distinct_relation_rows(rows : Array[Record]) -> Array[Record] {
  let seen : Array[String] = []
  let distinct : Array[Record] = []
  for row in rows {
    let signature = row.table + ":" + @support.entries_to_json(row.fields)
    if not(seen.contains(signature)) {
      seen.push(signature)
      distinct.push(row)
    }
  }
  distinct
}

///|
fn window_relation_rows(
  rows : Array[Record],
  offset : Int?,
  limit : Int?,
) -> Array[Record] {
  let visible : Array[Record] = []
  let start = match offset {
    Some(value) => value.clamp(min=0, max=rows.length())
    None => 0
  }
  let stop = match limit {
    Some(value) => (start + value).clamp(min=start, max=rows.length())
    None => rows.length()
  }
  for index in start..<stop {
    visible.push(rows[index])
  }
  visible
}

///|
fn compare_rows_for_order(
  schema : ModelSchema,
  table_name : String,
  left : Record,
  right : Record,
  orderings : Array[OrderBy],
) -> Int {
  for order in orderings {
    let result = compare_optional_values(
      record_value_for_column(left, order.column, table_name),
      record_value_for_column(right, order.column, table_name),
      match normalized_column_name(order.column, table_name) {
        Some(column) => find_column(schema, column)
        None => None
      },
    )
    if result != 0 {
      return if order.descending { -result } else { result }
    }
  }
  0
}
