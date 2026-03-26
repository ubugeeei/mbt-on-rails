///|
/// Chainable alias for `nullable`.
pub fn Column::nullable(self : Column) -> Column {
  { ..self, nullable: true }
}

///|
/// Chainable alias for `unique`.
pub fn Column::unique(self : Column) -> Column {
  { ..self, unique: true }
}

///|
/// Chainable alias for `indexed`.
pub fn Column::indexed(self : Column) -> Column {
  { ..self, indexed: true }
}

///|
/// Chainable alias for `with_default`.
pub fn Column::with_default(self : Column, default_value : String) -> Column {
  { ..self, default_value: Some(default_value) }
}

///|
/// Chainable alias for `with_association`.
pub fn ModelSchema::with_association(
  self : ModelSchema,
  association : Association,
) -> ModelSchema {
  let associations = @support.clone_array(self.associations)
  associations.push(association)
  { ..self, associations, }
}

///|
/// Chainable alias for `with_validation`.
pub fn ModelSchema::with_validation(
  self : ModelSchema,
  validation : Validation,
) -> ModelSchema {
  let validations = @support.clone_array(self.validations)
  validations.push(validation)
  { ..self, validations, }
}

///|
/// Chainable alias for `with_callback`.
pub fn ModelSchema::with_callback(
  self : ModelSchema,
  callback : Callback,
) -> ModelSchema {
  let callbacks = @support.clone_array(self.callbacks)
  callbacks.push(callback)
  { ..self, callbacks, }
}

///|
/// Chainable alias for `with_scope`.
pub fn ModelSchema::with_scope(
  self : ModelSchema,
  scope : ScopeDefinition,
) -> ModelSchema {
  let scopes = @support.clone_array(self.scopes)
  scopes.push(scope)
  { ..self, scopes, }
}

///|
/// Chainable alias for `select_columns`.
pub fn Relation::select_columns(
  self : Relation,
  selects : Array[String],
) -> Relation {
  { ..self, selects, }
}

///|
/// Chainable alias for `where_eq`.
pub fn Relation::where_eq(
  self : Relation,
  column : String,
  value : String,
) -> Relation {
  let predicates = @support.clone_array(self.predicates)
  predicates.push(Eq(column, value))
  { ..self, predicates, }
}

///|
/// Chainable alias for `where_like`.
pub fn Relation::where_like(
  self : Relation,
  column : String,
  value : String,
) -> Relation {
  let predicates = @support.clone_array(self.predicates)
  predicates.push(Like(column, value))
  { ..self, predicates, }
}

///|
/// Chainable alias for `where_not_eq`.
pub fn Relation::where_not_eq(
  self : Relation,
  column : String,
  value : String,
) -> Relation {
  let predicates = @support.clone_array(self.predicates)
  predicates.push(NotEq(column, value))
  { ..self, predicates, }
}

///|
/// Chainable alias for `where_gt`.
pub fn Relation::where_gt(
  self : Relation,
  column : String,
  value : String,
) -> Relation {
  let predicates = @support.clone_array(self.predicates)
  predicates.push(Gt(column, value))
  { ..self, predicates, }
}

///|
/// Chainable alias for `where_lt`.
pub fn Relation::where_lt(
  self : Relation,
  column : String,
  value : String,
) -> Relation {
  let predicates = @support.clone_array(self.predicates)
  predicates.push(Lt(column, value))
  { ..self, predicates, }
}

///|
/// Chainable alias for `where_in`.
pub fn Relation::where_in(
  self : Relation,
  column : String,
  values : Array[String],
) -> Relation {
  let predicates = @support.clone_array(self.predicates)
  predicates.push(InList(column, values))
  { ..self, predicates, }
}

///|
/// Chainable alias for `where_raw`.
pub fn Relation::where_raw(self : Relation, sql : String) -> Relation {
  let predicates = @support.clone_array(self.predicates)
  predicates.push(Raw(sql))
  { ..self, predicates, }
}

///|
/// Chainable alias for `order_by`.
pub fn Relation::order_by(
  self : Relation,
  column : String,
  descending? : Bool = false,
) -> Relation {
  let orderings = @support.clone_array(self.orderings)
  orderings.push({ column, descending })
  { ..self, orderings, }
}

///|
/// Chainable alias for `preload`.
pub fn Relation::preload(self : Relation, association : String) -> Relation {
  let preloads = @support.clone_array(self.preloads)
  preloads.push(association)
  { ..self, preloads, }
}

///|
/// Chainable alias for `limit_to`.
pub fn Relation::limit_to(self : Relation, count : Int) -> Relation {
  { ..self, limit: Some(count) }
}

///|
/// Chainable alias for `offset_by`.
pub fn Relation::offset_by(self : Relation, count : Int) -> Relation {
  { ..self, offset: Some(count) }
}

///|
/// Chainable alias for `join_relation`.
pub fn Relation::join_relation(self : Relation, join_sql : String) -> Relation {
  let joins = @support.clone_array(self.joins)
  joins.push(join_sql)
  { ..self, joins, }
}

///|
/// Chainable alias for `distinct_records`.
pub fn Relation::distinct_records(self : Relation) -> Relation {
  { ..self, distinct: true }
}

///|
/// Chainable alias for `reorder_by`.
pub fn Relation::reorder_by(
  self : Relation,
  column : String,
  descending? : Bool = false,
) -> Relation {
  { ..self, orderings: [{ column, descending }] }
}

///|
/// Chainable alias for `reverse_order`.
pub fn Relation::reverse_order(self : Relation) -> Relation {
  let orderings : Array[OrderBy] = []
  for order in self.orderings {
    orderings.push({ column: order.column, descending: not(order.descending) })
  }
  { ..self, orderings, }
}

///|
/// Chainable alias for `group_by`.
pub fn Relation::group_by(self : Relation, columns : Array[String]) -> Relation {
  let groupings = @support.clone_array(self.groupings)
  for column in columns {
    groupings.push(column)
  }
  { ..self, groupings, }
}

///|
/// Chainable alias for `having_raw`.
pub fn Relation::having_raw(self : Relation, sql : String) -> Relation {
  let having_clauses = @support.clone_array(self.having_clauses)
  having_clauses.push(sql)
  { ..self, having_clauses, }
}

///|
/// Chainable alias for `none_relation`.
pub fn Relation::none_relation(self : Relation) -> Relation {
  { ..self, none: true }
}

///|
/// Chainable alias for `merge_relation`.
pub fn Relation::merge_relation(self : Relation, other : Relation) -> Relation {
  let selects = if other.selects == ["*"] {
    @support.clone_array(self.selects)
  } else if self.selects == ["*"] {
    @support.clone_array(other.selects)
  } else {
    let merged = @support.clone_array(self.selects)
    for select in other.selects {
      merged.push(select)
    }
    merged
  }
  let predicates = @support.clone_array(self.predicates)
  for predicate in other.predicates {
    predicates.push(predicate)
  }
  let orderings = @support.clone_array(self.orderings)
  for order in other.orderings {
    orderings.push(order)
  }
  let joins = @support.clone_array(self.joins)
  for join_sql in other.joins {
    joins.push(join_sql)
  }
  let groupings = @support.clone_array(self.groupings)
  for group in other.groupings {
    groupings.push(group)
  }
  let having_clauses = @support.clone_array(self.having_clauses)
  for clause in other.having_clauses {
    having_clauses.push(clause)
  }
  let preloads = @support.clone_array(self.preloads)
  for association in other.preloads {
    preloads.push(association)
  }
  {
    table: self.table,
    selects,
    predicates,
    orderings,
    joins,
    groupings,
    having_clauses,
    distinct: self.distinct || other.distinct,
    none: self.none || other.none,
    limit: match other.limit {
      Some(limit) => Some(limit)
      None => self.limit
    },
    offset: match other.offset {
      Some(offset) => Some(offset)
      None => self.offset
    },
    preloads,
  }
}
