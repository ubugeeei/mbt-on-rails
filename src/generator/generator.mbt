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
  let model = scaffold_model(resource_name, fields)
  let controller = @controller.restful_controller_with_params(
    resource_name,
    resource_name,
    scaffold_field_names(fields),
  )
  let routes = @http.resources(
    resource_name,
    controller.name,
    @http.with_member_action(
      @http.default_resource_options(resource_name, Some(resource_name)),
      "publish",
      @http.http_post(),
    ),
  )
  let application_layout = scaffold_application_layout()
  let pages = scaffold_pages(resource_name, application_layout)
  let server_actions = scaffold_server_actions(resource_name, fields)
  let artifacts = scaffold_artifacts(resource_name)
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
  lines.push("  pages: " + plan.pages.length().to_string())
  lines.push("  actions: " + plan.server_actions.length().to_string())
  for artifact in plan.artifacts {
    lines.push("  file: " + artifact.path + " (" + artifact.description + ")")
  }
  lines.join("\n")
}

///|
fn scaffold_model(
  resource_name : String,
  fields : Array[ScaffoldField],
) -> @orm.ModelSchema {
  let columns : Array[@orm.Column] = []
  for field in fields {
    columns.push(field.column)
  }

  let singular = @support.singularize(resource_name)
  let mut model = @orm.model(
    name=@support.classify(singular),
    table=resource_name,
    columns~,
  )

  match scaffold_primary_field(fields) {
    Some(field_name) =>
      model = @orm.with_validation(
        model,
        @orm.validates_presence(field=field_name),
      )
    None => ()
  }

  if scaffold_has_slug(fields) {
    model = @orm.with_validation(model, @orm.validates_uniqueness(field="slug"))
    model = @orm.with_callback(
      model,
      @orm.before_validation("normalize_" + singular + "_slug"),
    )
  }

  for association in scaffold_associations(fields) {
    model = @orm.with_association(model, association)
  }

  model
}

///|
fn scaffold_primary_field(fields : Array[ScaffoldField]) -> String? {
  for field in fields {
    match field.column.column_type {
      @orm.References(_) => ()
      _ => return Some(field.name)
    }
  }
  if fields.is_empty() {
    None
  } else {
    Some(fields[0].name)
  }
}

///|
fn scaffold_has_slug(fields : Array[ScaffoldField]) -> Bool {
  fields.any(fn(field) { field.name == "slug" })
}

///|
fn scaffold_associations(
  fields : Array[ScaffoldField],
) -> Array[@orm.Association] {
  let associations : Array[@orm.Association] = []
  for field in fields {
    match field.column.column_type {
      @orm.References(table) =>
        associations.push(
          @orm.belongs_to(
            name=scaffold_reference_name(field.name),
            target=@support.classify(@support.singularize(table)),
            foreign_key=field.name,
          ),
        )
      _ => ()
    }
  }
  associations
}

///|
fn scaffold_reference_name(field_name : String) -> String {
  if field_name.has_suffix("_id") && field_name.length() > 3 {
    String::unsafe_substring(field_name, start=0, end=field_name.length() - 3)
  } else {
    field_name
  }
}

///|
fn scaffold_field_names(fields : Array[ScaffoldField]) -> Array[String] {
  let names : Array[String] = []
  for field in fields {
    names.push(field.name)
  }
  names
}

///|
fn scaffold_application_layout() -> @view.LayoutModule {
  @view.layout_module(
    name="application",
    file_path=@support.mbtv_path(
      "examples/scaffold/views/layouts/application.mbtv",
    ),
    component=@view.server_component(
      name="ApplicationLayout",
      source_path=@support.mbtv_path(
        "examples/scaffold/views/layouts/application.mbtv",
      ),
      props=[],
    ),
  )
}

///|
fn scaffold_pages(
  resource_name : String,
  application_layout : @view.LayoutModule,
) -> Array[@view.PageModule] {
  let singular = @support.singularize(resource_name)
  let singular_class = @support.classify(singular)
  let collection_class = @support.classify(resource_name)
  let create_form = scaffold_form_binding(resource_name, "create")
  let update_form = scaffold_form_binding(resource_name, "update")
  let destroy_form = scaffold_form_binding(resource_name, "destroy")
  [
    @view.page_module(
      route_name=resource_name + "_index",
      route_path="/" + resource_name,
      file_path=scaffold_page_path(resource_name, "index"),
      title=collection_class,
      component=@view.server_component(
        name=collection_class + "IndexPage",
        source_path=scaffold_page_path(resource_name, "index"),
        props=[],
      ),
    )
    .with_layout(application_layout)
    .with_loader(
      @view.loader_module(
        name="load_" + resource_name,
        cache_key=resource_name + ":index",
        revalidate_seconds=Some(60),
        depends_on=[resource_name],
      ),
    )
    .with_action_name(resource_name + ".create")
    .with_dynamic_mode(@view.dynamic_revalidate(60))
    .with_island(scaffold_counter_island(resource_name))
    .with_form(create_form),
    @view.page_module(
      route_name=resource_name + "_show",
      route_path="/" + resource_name + "/[id]",
      file_path=scaffold_page_path(resource_name, "show"),
      title=singular_class,
      component=@view.server_component(
        name=singular_class + "ShowPage",
        source_path=scaffold_page_path(resource_name, "show"),
        props=[],
      ),
    )
    .with_layout(application_layout)
    .with_loader(
      @view.loader_module(
        name="load_" + singular,
        cache_key=resource_name + ":show",
        revalidate_seconds=None,
        depends_on=[resource_name],
      ),
    )
    .with_action_name(resource_name + ".update")
    .with_form(update_form)
    .with_form(destroy_form),
    @view.page_module(
      route_name=resource_name + "_new",
      route_path="/" + resource_name + "/new",
      file_path=scaffold_page_path(resource_name, "new"),
      title="New " + singular_class,
      component=@view.server_component(
        name=singular_class + "NewPage",
        source_path=scaffold_page_path(resource_name, "new"),
        props=[],
      ),
    )
    .with_layout(application_layout)
    .with_form(create_form),
    @view.page_module(
      route_name=resource_name + "_edit",
      route_path="/" + resource_name + "/[id]/edit",
      file_path=scaffold_page_path(resource_name, "edit"),
      title="Edit " + singular_class,
      component=@view.server_component(
        name=singular_class + "EditPage",
        source_path=scaffold_page_path(resource_name, "edit"),
        props=[],
      ),
    )
    .with_layout(application_layout)
    .with_loader(
      @view.loader_module(
        name="load_" + singular + "_for_edit",
        cache_key=resource_name + ":edit",
        revalidate_seconds=None,
        depends_on=[resource_name],
      ),
    )
    .with_form(update_form),
  ]
}

///|
fn scaffold_form_binding(
  resource_name : String,
  action_name : String,
) -> @view.FormBinding {
  let singular = @support.singularize(resource_name)
  match action_name {
    "create" =>
      @view.form_binding(
        name=singular + "_create",
        action_name=resource_name + ".create",
        verb="POST",
        optimistic_key=Some(resource_name),
        redirect_to=Some("/" + resource_name),
      )
    "update" =>
      @view.form_binding(
        name=singular + "_update",
        action_name=resource_name + ".update",
        verb="POST",
        optimistic_key=Some(singular),
        redirect_to=Some("/" + resource_name + "/[id]"),
      )
    "destroy" =>
      @view.form_binding(
        name=singular + "_destroy",
        action_name=resource_name + ".destroy",
        verb="POST",
        optimistic_key=Some(resource_name),
        redirect_to=Some("/" + resource_name),
      )
    _ =>
      @view.form_binding(
        name=singular + "_form",
        action_name=resource_name + "." + action_name,
        verb="POST",
        optimistic_key=None,
        redirect_to=None,
      )
  }
}

///|
fn scaffold_counter_island(resource_name : String) -> @view.VaporComponentRef {
  let singular = @support.singularize(resource_name)
  @view.with_contract(
    @view.with_fallback(
      @view.client_component(
        name=@support.classify(singular) + "Counter",
        source_path=scaffold_component_path(singular + "_counter"),
        props=[("count", "0")],
        hydration=@view.hydrate_visible(),
      ),
      "<button type=\"button\">0</button>",
    ),
    @view.client_contract(props=[
      @view.prop_contract(
        name="count",
        type_name="Int",
        required=true,
        description="Initial collection count preview",
      ),
    ]),
  )
}

///|
fn scaffold_server_actions(
  resource_name : String,
  fields : Array[ScaffoldField],
) -> Array[@view.ServerAction] {
  let payload_type = @support.classify(@support.singularize(resource_name)) +
    "Payload"
  let create_fields = scaffold_action_fields(fields)
  let update_fields : Array[(String, String)] = [("id", "String")]
  for field in create_fields {
    update_fields.push(field)
  }
  [
    @view.server_action(
      name=resource_name + ".create",
      route="/_actions/" + resource_name + ".create",
      input_fields=create_fields,
      output_type=payload_type,
      csrf_protected=true,
    ),
    @view.server_action(
      name=resource_name + ".update",
      route="/_actions/" + resource_name + ".update",
      input_fields=update_fields,
      output_type=payload_type,
      csrf_protected=true,
    ),
    @view.server_action(
      name=resource_name + ".destroy",
      route="/_actions/" + resource_name + ".destroy",
      input_fields=[("id", "String")],
      output_type="Unit",
      csrf_protected=true,
    ),
  ]
}

///|
fn scaffold_action_fields(
  fields : Array[ScaffoldField],
) -> Array[(String, String)] {
  let action_fields : Array[(String, String)] = []
  for field in fields {
    action_fields.push((field.name, scaffold_input_type(field.column)))
  }
  action_fields
}

///|
fn scaffold_input_type(column : @orm.Column) -> String {
  let base_type = match column.column_type {
    @orm.Varchar => "String"
    @orm.Text => "String"
    @orm.Integer => "Int"
    @orm.Boolean => "Bool"
    @orm.Timestamp => "String"
    @orm.Json => "String"
    @orm.References(_) => "String"
  }
  if column.nullable {
    base_type + "?"
  } else {
    base_type
  }
}

///|
fn scaffold_artifacts(resource_name : String) -> Array[GeneratedArtifact] {
  let singular = @support.singularize(resource_name)
  [
    {
      path: "examples/scaffold/views/pages/" + resource_name + "/index.mbtv",
      description: "index page",
    },
    {
      path: "examples/scaffold/views/pages/" + resource_name + "/show.mbtv",
      description: "show page",
    },
    {
      path: "examples/scaffold/views/pages/" + resource_name + "/new.mbtv",
      description: "new page",
    },
    {
      path: "examples/scaffold/views/pages/" + resource_name + "/edit.mbtv",
      description: "edit page",
    },
    {
      path: "examples/scaffold/views/components/" + singular + "_form.mbtv",
      description: "form component",
    },
    {
      path: "examples/scaffold/views/components/" + singular + "_counter.mbtv",
      description: "client island component",
    },
    {
      path: "examples/scaffold/generated_types.mbt",
      description: "typed route and server action helpers",
    },
    {
      path: "examples/scaffold/db/migrate/TIMESTAMP_create_" +
      resource_name +
      ".mbt",
      description: "migration plan",
    },
  ]
}

///|
fn scaffold_page_path(
  resource_name : String,
  page_name : String,
) -> @support.MbtvPath {
  @support.mbtv_path(
    "examples/scaffold/views/pages/" + resource_name + "/" + page_name + ".mbtv",
  )
}

///|
fn scaffold_component_path(component_name : String) -> @support.MbtvPath {
  @support.mbtv_path(
    "examples/scaffold/views/components/" + component_name + ".mbtv",
  )
}
