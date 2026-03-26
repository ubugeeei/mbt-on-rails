///|
/// Lists the predicate kinds supported by the query DSL.
pub enum Predicate {
  Eq(String, String)
  NotEq(String, String)
  Like(String, String)
  Gt(String, String)
  Lt(String, String)
  InList(String, Array[String])
  Raw(String)
} derive(Show)

///|
/// Describes one `ORDER BY` clause.
pub struct OrderBy {
  column : String
  descending : Bool
}

///|
/// Represents a relation being built up with query modifiers.
pub struct Relation {
  table : String
  selects : Array[String]
  predicates : Array[Predicate]
  orderings : Array[OrderBy]
  joins : Array[String]
  groupings : Array[String]
  having_clauses : Array[String]
  distinct : Bool
  none : Bool
  limit : Int?
  offset : Int?
  preloads : Array[String]
}

///|
/// Starts a relation targeting the supplied model's table.
pub fn relation_for(model : ModelSchema) -> Relation {
  {
    table: model.table,
    selects: ["*"],
    predicates: [],
    orderings: [],
    joins: [],
    groupings: [],
    having_clauses: [],
    distinct: false,
    none: false,
    limit: None,
    offset: None,
    preloads: [],
  }
}

///|
/// Overrides the columns selected by a relation.
pub fn select_columns(relation : Relation, selects : Array[String]) -> Relation {
  { ..relation, selects, }
}

///|
/// Adds an equality predicate to a relation.
pub fn where_eq(
  relation : Relation,
  column : String,
  value : String,
) -> Relation {
  let predicates = @support.clone_array(relation.predicates)
  predicates.push(Eq(column, value))
  { ..relation, predicates, }
}

///|
/// Adds a `LIKE` predicate to a relation.
pub fn where_like(
  relation : Relation,
  column : String,
  value : String,
) -> Relation {
  let predicates = @support.clone_array(relation.predicates)
  predicates.push(Like(column, value))
  { ..relation, predicates, }
}

///|
/// Adds a non-equality predicate to a relation.
pub fn where_not_eq(
  relation : Relation,
  column : String,
  value : String,
) -> Relation {
  let predicates = @support.clone_array(relation.predicates)
  predicates.push(NotEq(column, value))
  { ..relation, predicates, }
}

///|
/// Adds a greater-than predicate to a relation.
pub fn where_gt(
  relation : Relation,
  column : String,
  value : String,
) -> Relation {
  let predicates = @support.clone_array(relation.predicates)
  predicates.push(Gt(column, value))
  { ..relation, predicates, }
}

///|
/// Adds a less-than predicate to a relation.
pub fn where_lt(
  relation : Relation,
  column : String,
  value : String,
) -> Relation {
  let predicates = @support.clone_array(relation.predicates)
  predicates.push(Lt(column, value))
  { ..relation, predicates, }
}

///|
/// Adds an `IN (...)` predicate to a relation.
pub fn where_in(
  relation : Relation,
  column : String,
  values : Array[String],
) -> Relation {
  let predicates = @support.clone_array(relation.predicates)
  predicates.push(InList(column, values))
  { ..relation, predicates, }
}

///|
/// Adds a raw SQL predicate to a relation.
pub fn where_raw(relation : Relation, sql : String) -> Relation {
  let predicates = @support.clone_array(relation.predicates)
  predicates.push(Raw(sql))
  { ..relation, predicates, }
}

///|
/// Adds an `ORDER BY` clause to a relation.
pub fn order_by(
  relation : Relation,
  column : String,
  descending? : Bool = false,
) -> Relation {
  let orderings = @support.clone_array(relation.orderings)
  orderings.push({ column, descending })
  { ..relation, orderings, }
}

///|
/// Records an eager-load dependency for a relation.
pub fn preload(relation : Relation, association : String) -> Relation {
  let preloads = @support.clone_array(relation.preloads)
  preloads.push(association)
  { ..relation, preloads, }
}

///|
/// Adds a limit clause to a relation.
pub fn limit_to(relation : Relation, count : Int) -> Relation {
  { ..relation, limit: Some(count) }
}

///|
/// Adds an offset clause to a relation.
pub fn offset_by(relation : Relation, count : Int) -> Relation {
  { ..relation, offset: Some(count) }
}

///|
/// Appends a raw join clause to a relation.
pub fn join_relation(relation : Relation, join_sql : String) -> Relation {
  let joins = @support.clone_array(relation.joins)
  joins.push(join_sql)
  { ..relation, joins, }
}

///|
/// Marks the relation as selecting distinct rows.
pub fn distinct_records(relation : Relation) -> Relation {
  { ..relation, distinct: true }
}

///|
/// Replaces the relation ordering with one explicit clause.
pub fn reorder_by(
  relation : Relation,
  column : String,
  descending? : Bool = false,
) -> Relation {
  { ..relation, orderings: [{ column, descending }] }
}

///|
/// Reverses all configured relation orderings.
pub fn reverse_order(relation : Relation) -> Relation {
  let orderings : Array[OrderBy] = []
  for order in relation.orderings {
    orderings.push({ column: order.column, descending: not(order.descending) })
  }
  { ..relation, orderings, }
}

///|
/// Adds one `GROUP BY` clause to a relation.
pub fn group_by(relation : Relation, columns : Array[String]) -> Relation {
  let groupings = @support.clone_array(relation.groupings)
  for column in columns {
    groupings.push(column)
  }
  { ..relation, groupings, }
}

///|
/// Adds one raw `HAVING` clause to a relation.
pub fn having_raw(relation : Relation, sql : String) -> Relation {
  let having_clauses = @support.clone_array(relation.having_clauses)
  having_clauses.push(sql)
  { ..relation, having_clauses, }
}

///|
/// Marks the relation as empty, mirroring `none`.
pub fn none_relation(relation : Relation) -> Relation {
  { ..relation, none: true }
}

///|
/// Merges two relations in a Rails-like append/override style.
pub fn merge_relation(left : Relation, right : Relation) -> Relation {
  let selects = merge_selects(left.selects, right.selects)
  let predicates = @support.clone_array(left.predicates)
  for predicate in right.predicates {
    predicates.push(predicate)
  }
  let orderings = @support.clone_array(left.orderings)
  for order in right.orderings {
    orderings.push(order)
  }
  let joins = @support.clone_array(left.joins)
  for join_sql in right.joins {
    joins.push(join_sql)
  }
  let groupings = @support.clone_array(left.groupings)
  for group in right.groupings {
    groupings.push(group)
  }
  let having_clauses = @support.clone_array(left.having_clauses)
  for clause in right.having_clauses {
    having_clauses.push(clause)
  }
  let preloads = @support.clone_array(left.preloads)
  for association in right.preloads {
    preloads.push(association)
  }
  {
    table: left.table,
    selects,
    predicates,
    orderings,
    joins,
    groupings,
    having_clauses,
    distinct: left.distinct || right.distinct,
    none: left.none || right.none,
    limit: merge_optional_int(left.limit, right.limit),
    offset: merge_optional_int(left.offset, right.offset),
    preloads,
  }
}

///|
/// Renders a relation as a SQL `SELECT` statement.
pub fn relation_to_sql(relation : Relation) -> String {
  let sb = StringBuilder::new()
  sb.write_string("SELECT ")
  if relation.distinct {
    sb.write_string("DISTINCT ")
  }
  sb.write_string(relation.selects.join(", "))
  sb.write_string(" FROM ")
  sb.write_string(relation.table)
  if not(relation.joins.is_empty()) {
    sb.write_char(' ')
    sb.write_string(relation.joins.join(" "))
  }
  let clauses : Array[String] = []
  if relation.none {
    clauses.push("1=0")
  }
  for predicate in relation.predicates {
    clauses.push(predicate_to_sql(predicate))
  }
  if not(clauses.is_empty()) {
    sb.write_string(" WHERE ")
    sb.write_string(clauses.join(" AND "))
  }
  if not(relation.groupings.is_empty()) {
    sb.write_string(" GROUP BY ")
    sb.write_string(relation.groupings.join(", "))
  }
  if not(relation.having_clauses.is_empty()) {
    sb.write_string(" HAVING ")
    sb.write_string(relation.having_clauses.join(" AND "))
  }
  if not(relation.orderings.is_empty()) {
    let parts : Array[String] = []
    for order in relation.orderings {
      let suffix = if order.descending { "DESC" } else { "ASC" }
      parts.push(order.column + " " + suffix)
    }
    sb.write_string(" ORDER BY ")
    sb.write_string(parts.join(", "))
  }
  match relation.limit {
    Some(limit) => sb.write_string(" LIMIT " + limit.to_string())
    None => ()
  }
  match relation.offset {
    Some(offset) => sb.write_string(" OFFSET " + offset.to_string())
    None => ()
  }
  sb.to_string()
}

///|
/// Renders a relation as a SQL `COUNT(*)` statement.
pub fn count_sql(relation : Relation) -> String {
  relation_to_sql({ ..relation, selects: ["COUNT(*)"] })
}

///|
/// Renders a relation as a SQL `SELECT` limited to one existence probe.
pub fn exists_sql(relation : Relation) -> String {
  relation_to_sql({ ..relation, selects: ["1 AS one"], limit: Some(1) })
}

///|
/// Renders a relation selecting only the supplied columns.
pub fn pluck_sql(relation : Relation, columns : Array[String]) -> String {
  relation_to_sql({ ..relation, selects: columns })
}

///|
fn merge_selects(left : Array[String], right : Array[String]) -> Array[String] {
  if right == ["*"] {
    return @support.clone_array(left)
  }
  if left == ["*"] {
    return @support.clone_array(right)
  }
  let selects = @support.clone_array(left)
  for select in right {
    selects.push(select)
  }
  selects
}

///|
fn merge_optional_int(left : Int?, right : Int?) -> Int? {
  match right {
    Some(value) => Some(value)
    None => left
  }
}

///|
/// Renders one predicate as a SQL clause fragment.
fn predicate_to_sql(predicate : Predicate) -> String {
  match predicate {
    Eq(column, value) => column + " = " + @support.sql_literal(value)
    NotEq(column, value) => column + " <> " + @support.sql_literal(value)
    Like(column, value) => column + " LIKE " + @support.sql_literal(value)
    Gt(column, value) => column + " > " + @support.sql_literal(value)
    Lt(column, value) => column + " < " + @support.sql_literal(value)
    InList(column, values) => {
      let literals : Array[String] = []
      for value in values {
        literals.push(@support.sql_literal(value))
      }
      column + " IN (" + literals.join(", ") + ")"
    }
    Raw(sql) => sql
  }
}
