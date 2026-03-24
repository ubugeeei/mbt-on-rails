///|
/// Represents one secret or environment variable contract.
pub struct SecretVar {
  name : String
  value : String?
  required : Bool
  sensitive : Bool
}

///|
/// Groups the secrets used by one deployment.
pub struct SecretsConfig {
  entries : Array[SecretVar]
}

///|
/// Builds one secret declaration.
pub fn secret_var(
  name : String,
  value : String?,
  required : Bool,
  sensitive : Bool,
) -> SecretVar {
  { name, value, required, sensitive }
}

///|
/// Builds one secret config.
pub fn secrets_config(entries : Array[SecretVar]) -> SecretsConfig {
  { entries, }
}

///|
/// Looks up one secret value by name.
pub fn secret_value(config : SecretsConfig, name : String) -> String? {
  for entry in config.entries {
    if entry.name == name {
      return entry.value
    }
  }
  None
}
