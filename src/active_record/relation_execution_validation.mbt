///|
fn relation_execution_issues(
  schema : ModelSchema,
  relation : Relation,
) -> Array[RelationExecutionIssue] {
  let issues : Array[RelationExecutionIssue] = []
  if relation.table != schema.table {
    issues.push(
      relation_execution_issue(
        "table",
        "relation targets " +
        relation.table +
        " but schema targets " +
        schema.table,
      ),
    )
  }
  if not(relation.joins.is_empty()) {
    issues.push(
      relation_execution_issue(
        "joins", "join execution is not implemented for the in-memory adapter",
      ),
    )
  }
  if not(relation.groupings.is_empty()) {
    issues.push(
      relation_execution_issue(
        "group_by", "grouped relation execution is not implemented for the in-memory adapter",
      ),
    )
  }
  if not(relation.having_clauses.is_empty()) {
    issues.push(
      relation_execution_issue(
        "having", "having-clause execution is not implemented for the in-memory adapter",
      ),
    )
  }
  if not(relation.preloads.is_empty()) {
    issues.push(
      relation_execution_issue(
        "preload", "association preloading is not implemented for the in-memory adapter",
      ),
    )
  }
  validate_select_columns(schema, relation, issues)
  validate_predicate_columns(schema, relation, issues)
  validate_order_columns(schema, relation, issues)
  issues
}

///|
fn validate_select_columns(
  schema : ModelSchema,
  relation : Relation,
  issues : Array[RelationExecutionIssue],
) -> Unit {
  for select in relation.selects {
    match simple_select_column(select, relation.table) {
      Some("*") => ()
      Some(column) =>
        ensure_known_relation_column(schema, column, "select", issues)
      None =>
        issues.push(
          relation_execution_issue(
            "select",
            "complex select expressions are not executable in memory: " + select,
          ),
        )
    }
  }
}

///|
fn validate_predicate_columns(
  schema : ModelSchema,
  relation : Relation,
  issues : Array[RelationExecutionIssue],
) -> Unit {
  for predicate in relation.predicates {
    match predicate {
      Eq(column, _) =>
        ensure_known_relation_column(schema, column, "predicate", issues)
      NotEq(column, _) =>
        ensure_known_relation_column(schema, column, "predicate", issues)
      Like(column, _) =>
        ensure_known_relation_column(schema, column, "predicate", issues)
      Gt(column, _) =>
        ensure_known_relation_column(schema, column, "predicate", issues)
      Lt(column, _) =>
        ensure_known_relation_column(schema, column, "predicate", issues)
      InList(column, _) =>
        ensure_known_relation_column(schema, column, "predicate", issues)
      Raw(sql) =>
        issues.push(
          relation_execution_issue(
            "raw_predicate",
            "raw predicates are not executable in memory: " + sql,
          ),
        )
    }
  }
}

///|
fn validate_order_columns(
  schema : ModelSchema,
  relation : Relation,
  issues : Array[RelationExecutionIssue],
) -> Unit {
  for order in relation.orderings {
    ensure_known_relation_column(schema, order.column, "order", issues)
  }
}

///|
fn ensure_known_relation_column(
  schema : ModelSchema,
  source : String,
  feature : String,
  issues : Array[RelationExecutionIssue],
) -> Unit {
  match normalized_column_name(source, schema.table) {
    Some(column) =>
      match find_column(schema, column) {
        Some(_) => ()
        None =>
          issues.push(
            relation_execution_issue(
              feature,
              "unknown schema column for in-memory execution: " + source,
            ),
          )
      }
    None =>
      issues.push(
        relation_execution_issue(
          feature,
          "complex column reference is not executable in memory: " + source,
        ),
      )
  }
}
