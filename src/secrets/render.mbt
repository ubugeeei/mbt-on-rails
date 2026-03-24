///|
/// Returns the list of required secrets that are still missing.
pub fn missing_secrets(config : SecretsConfig) -> Array[String] {
  let missing : Array[String] = []
  for entry in config.entries {
    if entry.required && entry.value is None {
      missing.push(entry.name)
    }
  }
  missing
}

///|
/// Returns whether all required secrets are present.
pub fn secrets_valid(config : SecretsConfig) -> Bool {
  missing_secrets(config).is_empty()
}

///|
/// Renders a masked summary for logs or diagnostics.
pub fn masked_secret_summary(config : SecretsConfig) -> String {
  let lines : Array[String] = []
  for entry in config.entries {
    let value = match entry.value {
      Some(current) =>
        if entry.sensitive {
          mask_secret(current)
        } else {
          current
        }
      None => "<missing>"
    }
    lines.push(entry.name + "=" + value)
  }
  lines.join("\n")
}

///|
/// Renders a `.env`-style file preview.
pub fn dotenv_preview(config : SecretsConfig) -> String {
  let lines : Array[String] = []
  for entry in config.entries {
    match entry.value {
      Some(value) => lines.push(entry.name + "=" + value)
      None => ()
    }
  }
  lines.join("\n")
}

///|
/// Masks a secret value while keeping a tiny hint of its shape.
fn mask_secret(value : String) -> String {
  if value.length() <= 4 {
    return "****"
  }
  let prefix = String::unsafe_substring(value, start=0, end=2)
  let suffix = String::unsafe_substring(
    value,
    start=value.length() - 2,
    end=value.length(),
  )
  prefix + "****" + suffix
}
