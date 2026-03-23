///|
/// Evaluates whether an identity satisfies a direct auth requirement.
pub fn authorize(identity : Identity?, requirement : AuthRequirement) -> Bool {
  match requirement {
    Public => true
    GuestOnly => identity is None
    Authenticated => identity is Some(_)
    Role(required_role) =>
      match identity {
        Some(current) =>
          current.role == "admin" || current.role == required_role
        None => false
      }
    Permission(required_permission) =>
      match identity {
        Some(current) => {
          if current.role == "admin" {
            return true
          }
          current.permissions.contains(required_permission)
        }
        None => false
      }
  }
}

///|
/// Evaluates a richer policy rule, optionally allowing ownership.
pub fn allowed(
  identity : Identity?,
  rule : PolicyRule,
  owner_id : String?,
) -> Bool {
  match identity {
    None => false
    Some(current) => {
      if current.role == "admin" {
        return true
      }
      for role in rule.roles {
        if current.role == role {
          return true
        }
      }
      for permission in rule.permissions {
        if current.permissions.contains(permission) {
          return true
        }
      }
      if rule.allow_owner {
        match owner_id {
          Some(target_owner_id) => current.user_id == target_owner_id
          None => false
        }
      } else {
        false
      }
    }
  }
}
