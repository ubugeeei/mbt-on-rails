///|
/// Declares one explicit import that a template may render.
pub fn template_import(
  local_name~ : String,
  component~ : VaporComponentRef,
) -> TemplateImport {
  { local_name, component }
}

///|
/// Mounts one imported component with explicit props.
pub fn mount_import(
  import_name~ : String,
  props~ : Array[(String, String)],
) -> VaporNode {
  Mounted({ import_name, props })
}

///|
/// Builds one suspense-like boundary for nested server rendering.
pub fn suspense_boundary(
  name~ : String,
  fallback_html~ : String,
  children~ : Array[VaporNode],
) -> VaporNode {
  Suspense({ name, fallback_html, children })
}

///|
/// Attaches one explicit template import to a component.
pub fn with_template_import(
  component : VaporComponentRef,
  imported : TemplateImport,
) -> VaporComponentRef {
  let template_imports = @support.clone_array(component.template_imports)
  template_imports.push(imported)
  { ..component, template_imports, }
}

///|
/// Attaches one nested render node to a component.
pub fn with_child(
  component : VaporComponentRef,
  child : VaporNode,
) -> VaporComponentRef {
  let children = @support.clone_array(component.children)
  children.push(child)
  { ..component, children, }
}

///|
/// Validates one component tree and returns explicit boundary/import errors.
pub fn validate_component_tree(component : VaporComponentRef) -> Array[String] {
  let errors : Array[String] = []
  validate_component_tree_into(component, errors)
  errors
}

///|
/// Validates one page tree and returns explicit boundary/import errors.
pub fn validate_page_tree(page : PageModule) -> Array[String] {
  let errors : Array[String] = []
  validate_component_tree_into(page.component, errors)
  for layout in page.layouts {
    validate_component_tree_into(layout.component, errors)
  }
  for island in page.client_islands {
    validate_component_tree_into(island, errors)
  }
  errors
}

fn validate_component_tree_into(
  component : VaporComponentRef,
  errors : Array[String],
) -> Unit {
  let seen_names : Array[String] = []
  for imported in component.template_imports {
    if seen_names.contains(imported.local_name) {
      errors.push(
        component.name +
        " declares duplicate template import " +
        imported.local_name,
      )
    } else {
      seen_names.push(imported.local_name)
    }
    if is_client_boundary(component) && is_server_boundary(imported.component) {
      errors.push(
        component.name +
        " cannot import server component " +
        imported.local_name +
        " across a client boundary",
      )
    }
    validate_component_tree_into(imported.component, errors)
  }
  for child in component.children {
    validate_child(component, child, errors)
  }
}

fn validate_child(
  parent : VaporComponentRef,
  child : VaporNode,
  errors : Array[String],
) -> Unit {
  match child {
    Mounted(mounted) =>
      match resolve_template_import(parent, mounted.import_name) {
        Some(imported) => {
          let effective_props = merge_props(imported.component.props, mounted.props)
          validate_props(
            parent.name,
            imported.local_name,
            imported.component,
            effective_props,
            errors,
          )
        }
        None =>
          errors.push(
            parent.name +
            " mounts " +
            mounted.import_name +
            " without a matching template import",
          )
      }
    Suspense(boundary) => {
      if is_client_boundary(parent) {
        errors.push(
          parent.name +
          " cannot declare suspense boundary " +
          boundary.name +
          " inside a client component",
        )
      }
      for nested in boundary.children {
        validate_child(parent, nested, errors)
      }
    }
  }
}

fn validate_props(
  parent_name : String,
  import_name : String,
  component : VaporComponentRef,
  props : Array[(String, String)],
  errors : Array[String],
) -> Unit {
  match component.contract {
    Some(contract) => {
      for prop in props {
        let known = contract.props.any(fn(current) { current.name == prop.0 })
        if not(known) {
          errors.push(
            parent_name +
            " passes undeclared prop " +
            prop.0 +
            " to " +
            import_name,
          )
        }
      }
      for contract_prop in contract.props {
        if contract_prop.required &&
          not(props.any(fn(current) { current.0 == contract_prop.name })) {
          errors.push(
            parent_name +
            " is missing required prop " +
            contract_prop.name +
            " for " +
            import_name,
          )
        }
      }
    }
    None => ()
  }
}

fn resolve_template_import(
  component : VaporComponentRef,
  local_name : String,
) -> TemplateImport? {
  for imported in component.template_imports {
    if imported.local_name == local_name {
      return Some(imported)
    }
  }
  None
}

fn merge_props(
  base : Array[(String, String)],
  overrides : Array[(String, String)],
) -> Array[(String, String)] {
  let merged = @support.clone_array(base)
  for entry in overrides {
    let mut replaced = false
    for i = 0; i < merged.length(); i = i + 1 {
      if merged[i].0 == entry.0 {
        merged[i] = entry
        replaced = true
      }
    }
    if not(replaced) {
      merged.push(entry)
    }
  }
  merged
}

fn is_client_boundary(component : VaporComponentRef) -> Bool {
  match component.contract {
    Some(contract) => contract.boundary == ClientBoundary
    None => not(component.is_server_component)
  }
}

fn is_server_boundary(component : VaporComponentRef) -> Bool {
  not(is_client_boundary(component))
}
