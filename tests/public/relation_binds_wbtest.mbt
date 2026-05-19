///|
test "render_relation_bind quotes strings and renders typed literals" {
  assert_eq(render_relation_bind(BindText("plain")), "'plain'")
  assert_eq(render_relation_bind(BindText("with 'quote'")), "'with ''quote'''")
  assert_eq(render_relation_bind(BindInt(42L)), "42")
  assert_eq(render_relation_bind(BindInt(-7L)), "-7")
  assert_eq(render_relation_bind(BindBool(true)), "TRUE")
  assert_eq(render_relation_bind(BindBool(false)), "FALSE")
  assert_eq(render_relation_bind(BindNull), "NULL")
}

///|
test "substitute_relation_binds replaces ? placeholders in order" {
  let rendered = substitute_relation_binds("status = ? AND author_id = ?", [
    BindText("published"),
    BindInt(7L),
  ])
  assert_eq(rendered, "status = 'published' AND author_id = 7")
}

///|
test "substitute_relation_binds quotes injection attempts as data" {
  let payload = "'; DROP TABLE users; --"
  let rendered = substitute_relation_binds("name = ?", [BindText(payload)])
  // The injection payload is enclosed in a single SQL string with its
  // leading quote doubled (per the SQL standard's escape rule), so the
  // database parses the whole thing as one literal value rather than as
  // a statement terminator + a DROP TABLE follow-up.
  assert_eq(rendered, "name = '''; DROP TABLE users; --'")
  // The doubled-quote prefix is what neutralises the attack.
  assert_true(rendered.has_prefix("name = '''"))
  // And the literal stays terminated by a single trailing quote so the
  // SQL parser closes the string before reaching anything outside it.
  assert_true(rendered.has_suffix("--'"))
}

///|
test "substitute_relation_binds expands missing binds to NULL" {
  let rendered = substitute_relation_binds("a = ? AND b = ? AND c = ?", [
    BindInt(1L),
  ])
  assert_eq(rendered, "a = 1 AND b = NULL AND c = NULL")
}

///|
test "where_with_binds and having_with_binds substitute through the same pipeline" {
  let model = model(name="post", table="posts", columns=[
    indexed(string_column("title")),
    integer_column("views"),
    string_column("status"),
  ])
  let base = relation_for(model)
  let constrained = where_with_binds(base, "status = ? AND views > ?", [
    BindText("published"),
    BindInt(100L),
  ])
  let sql = relation_to_sql(constrained)
  assert_true(sql.contains("status = 'published'"))
  assert_true(sql.contains("views > 100"))
  let grouped = group_by(base, ["status"]).having_with_binds("count(*) > ?", [
    BindInt(5L),
  ])
  let grouped_sql = relation_to_sql(grouped)
  assert_true(grouped_sql.contains("HAVING count(*) > 5"))
}

///|
test "unsafe_where_raw still emits raw SQL so callers can opt in explicitly" {
  let model = model(name="post", table="posts", columns=[
    indexed(string_column("title")),
  ])
  let relation = unsafe_where_raw(relation_for(model), "title LIKE 'launch%'")
  let sql = relation_to_sql(relation)
  assert_true(sql.contains("title LIKE 'launch%'"))
}
