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
/// Renders a relation as a SQL `SELECT` statement.
pub fn relation_to_sql(relation : Relation) -> String {
  let sb = StringBuilder::new()
  sb.write_string("SELECT ")
  sb.write_string(relation.selects.join(", "))
  sb.write_string(" FROM ")
  sb.write_string(relation.table)
  if not(relation.joins.is_empty()) {
    sb.write_char(' ')
    sb.write_string(relation.joins.join(" "))
  }
  if not(relation.predicates.is_empty()) {
    let clauses : Array[String] = []
    for predicate in relation.predicates {
      clauses.push(predicate_to_sql(predicate))
    }
    sb.write_string(" WHERE ")
    sb.write_string(clauses.join(" AND "))
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
