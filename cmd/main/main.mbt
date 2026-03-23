///|
fn main {
  let app = @mbor.demo_blog_app()

  println("mbt on rails")
  println("============")
  println("")
  println("Auth")
  println(@mbor.auth_summary(app.auth))
  println("")
  println("Routes")
  println(app.routes_table())
  println("")
  println("Controllers")
  println(app.controller_table())
  println("")
  println("Schema")
  for statement in app.schema_statements() {
    println(statement)
  }
  println("")
  println("Schema Dump")
  println(app.schema_dump())
  println("")
  println("Router Manifest")
  println(app.router_manifest())
  println("")
  println("Route Tree")
  println(app.route_tree())
  println("")
  println("Scaffolds")
  println(app.scaffold_table())
  println("")
  println("SSR Example: /posts/42")
  match app.example_html("/posts/42") {
    Some(html) => println(html)
    None => println("no html")
  }
}
