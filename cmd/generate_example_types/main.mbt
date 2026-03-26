///|
/// Captures the CLI arguments needed to generate typed example helpers.
struct GenerateExampleTypesCommand {
  package_dir : String
  frontend_path : String
  output_path : String
}

///|
fn main {
  match parse_command(@env.args()) {
    Some(command) => run(command)
    None => print_usage()
  }
}

fn run(command : GenerateExampleTypesCommand) -> Unit {
  let package_dir = normalize_relative_path(command.package_dir)
  let frontend_path = normalize_relative_path(command.frontend_path)
  let output_path = normalize_relative_path(command.output_path)
  let views_dir = package_dir + "/views"
  let template_paths = discover_templates(views_dir)
  let frontend_source = read_text_file(frontend_path)
  let generated_source = @generator.generate_example_types_source(
    views_dir=views_dir,
    template_paths=template_paths,
    frontend_source=frontend_source,
  )
  write_text_file(output_path, generated_source)
}

fn parse_command(args : Array[String]) -> GenerateExampleTypesCommand? {
  if args.length() != 4 {
    return None
  }
  Some({
    package_dir: args[1],
    frontend_path: args[2],
    output_path: args[3],
  })
}

fn print_usage() -> Unit {
  println(
    "usage: moon run --target native cmd/generate_example_types -- <package_dir> <frontend_path> <output_path>",
  )
}

fn normalize_relative_path(path : String) -> String {
  let mut normalized = path.trim().to_string()
  while normalized.has_prefix("./") {
    normalized = String::unsafe_substring(
      normalized,
      start=2,
      end=normalized.length(),
    )
  }
  normalized
}
