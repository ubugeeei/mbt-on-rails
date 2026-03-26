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
    Raw(_) => false
  }
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
