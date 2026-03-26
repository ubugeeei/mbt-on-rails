///|
/// Describes one field in a scaffold request.
pub struct ScaffoldField {
  name : String
  column : @orm.Column
}

///|
/// Describes one file or output produced by scaffolding.
pub struct GeneratedArtifact {
  path : String
  description : String
}

///|
/// Collects the generated model, controller, routes, and pages for a resource.
pub struct ScaffoldPlan {
  resource_name : String
  model : @orm.ModelSchema
  controller : @controller.ControllerDefinition
  routes : Array[@http.RouteSpec]
  pages : Array[@view.PageModule]
  server_actions : Array[@view.ServerAction]
  artifacts : Array[GeneratedArtifact]
}

///|
/// Builds a scaffold field declaration.
pub fn scaffold_field(name : String, column : @orm.Column) -> ScaffoldField {
  { name, column }
}

///|
/// Builds a resource scaffold plan from a list of fields.
pub fn scaffold_resource(
  resource_name : String,
  fields : Array[ScaffoldField],
) -> ScaffoldPlan {
  let columns : Array[@orm.Column] = []
  for field in fields {
    columns.push(field.column)
  }
  let model = @orm.with_callback(
    @orm.with_validation(
      @orm.model(
        name=@support.classify(@support.singularize(resource_name)),
        table=resource_name,
        columns=columns,
      ),
      @orm.validates_presence("title"),
    ),
    @orm.before_save("normalize_" + @support.singularize(resource_name)),
  )
  let controller = @controller.restful_controller(resource_name, resource_name)
  let routes = @http.resources(
    resource_name,
    controller.name,
    @http.with_member_action(
      @http.default_resource_options(resource_name, Some(resource_name)),
      "publish",
      @http.http_post(),
    ),
  )
  let application_layout = @view.layout_module(
    "application",
    @support.mbtv_path("examples/scaffold/views/layouts/application.mbtv"),
    @view.server_component(
      "ApplicationLayout",
      @support.mbtv_path("examples/scaffold/views/layouts/application.mbtv"),
      [],
    ),
  )
  let pages = [
    @view.with_layout(
      @view.with_loader(
        @view.page_module(
          resource_name + "_index",
          "/" + resource_name,
          @support.mbtv_path(
            "examples/scaffold/views/pages/" + resource_name + "/index.mbtv",
          ),
          @support.classify(resource_name),
          @view.server_component(
            @support.classify(resource_name) + "IndexPage",
            @support.mbtv_path(
              "examples/scaffold/views/pages/" + resource_name + "/index.mbtv",
            ),
            [],
          ),
        ),
        @view.loader_module(
          "load_" + resource_name,
          resource_name + ":index",
          Some(60),
          [],
        ),
      ),
      application_layout,
    ),
    @view.with_layout(
      @view.page_module(
        resource_name + "_show",
        "/" + resource_name + "/[id]",
        @support.mbtv_path(
          "examples/scaffold/views/pages/" + resource_name + "/show.mbtv",
        ),
        @support.classify(@support.singularize(resource_name)),
        @view.server_component(
          @support.classify(resource_name) + "ShowPage",
          @support.mbtv_path(
            "examples/scaffold/views/pages/" + resource_name + "/show.mbtv",
          ),
          [],
        ),
      ),
      application_layout,
    ),
  ]
  let action_fields = fields.map(fn(field) {
    (field.name, field.column.column_type.to_string())
  })
  let server_actions = [
    @view.server_action(
      resource_name + ".create",
      "/_actions/" + resource_name + ".create",
      action_fields,
      @support.classify(@support.singularize(resource_name)) + "Payload",
      true,
    ),
    @view.server_action(
      resource_name + ".update",
      "/_actions/" + resource_name + ".update",
      action_fields,
      @support.classify(@support.singularize(resource_name)) + "Payload",
      true,
    ),
  ]
  let artifacts = [
    {
      path: "examples/scaffold/views/pages/" + resource_name + "/index.mbtv",
      description: "index page",
    },
    {
      path: "examples/scaffold/views/pages/" + resource_name + "/show.mbtv",
      description: "show page",
    },
    {
      path: "examples/scaffold/views/components/" +
      @support.singularize(resource_name) +
      "_form.mbtv",
      description: "form component",
    },
  ]
  { resource_name, model, controller, routes, pages, server_actions, artifacts }
}

///|
/// Renders a scaffold plan in a CLI-friendly summary format.
pub fn scaffold_summary(plan : ScaffoldPlan) -> String {
  let lines : Array[String] = []
  lines.push("Scaffold " + plan.resource_name)
  lines.push("  model: " + plan.model.name + " -> " + plan.model.table)
  lines.push("  controller: " + plan.controller.name)
  lines.push("  routes: " + plan.routes.length().to_string())
  lines.push("  actions: " + plan.server_actions.length().to_string())
  for artifact in plan.artifacts {
    lines.push("  file: " + artifact.path + " (" + artifact.description + ")")
  }
  lines.join("\n")
}
