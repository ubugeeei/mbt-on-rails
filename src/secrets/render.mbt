///|
/// Returns the list of required secrets that are still missing.
pub fn missing_secrets(config : SecretsConfig) -> Array[String] {
  let missing : Array[String] = []
  for entry in config.entries {
    if entry.required && secret_missing(entry.value) {
      missing.push(entry.name)
    }
  }
  missing
}

///|
/// Returns whether all required secrets are present.
pub fn secrets_valid(config : SecretsConfig) -> Bool {
  missing_secrets(config).is_empty() && invalid_secret_names(config).is_empty()
}

///|
/// Returns environment variable names that cannot be safely rendered or read.
pub fn invalid_secret_names(config : SecretsConfig) -> Array[String] {
  let invalid : Array[String] = []
  for entry in config.entries {
    if !valid_env_name(entry.name) {
      invalid.push(entry.name)
    }
  }
  invalid
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
    lines.push(summary_text(entry.name) + "=" + summary_text(value))
  }
  lines.join("\n")
}

///|
/// Renders a `.env`-style file preview.
pub fn dotenv_preview(config : SecretsConfig) -> String {
  let lines : Array[String] = []
  for entry in config.entries {
    match entry.value {
      Some(value) =>
        if !valid_env_name(entry.name) ||
          (entry.required && secret_missing(entry.value)) {
          ()
        } else if entry.sensitive {
          lines.push(entry.name + "=<redacted>")
        } else {
          lines.push(entry.name + "=" + dotenv_value(value))
        }
      None => ()
    }
  }
  lines.join("\n")
}

///|
fn secret_missing(value : String?) -> Bool {
  match value {
    Some(current) => current.trim().to_owned().length() == 0
    None => true
  }
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

///|
fn valid_env_name(name : String) -> Bool {
  if name.length() == 0 {
    return false
  }
  let mut index = 0
  for ch in name {
    let valid = if index == 0 {
      (ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z') || ch == '_'
    } else {
      (ch >= 'A' && ch <= 'Z') ||
      (ch >= 'a' && ch <= 'z') ||
      (ch >= '0' && ch <= '9') ||
      ch == '_'
    }
    if !valid {
      return false
    }
    index += 1
  }
  true
}

///|
fn dotenv_value(value : String) -> String {
  if !requires_dotenv_quotes(value) {
    return value
  }
  let builder = StringBuilder::new()
  builder.write_char('"')
  for ch in value {
    match ch {
      '"' => builder.write_string("\\\"")
      '\\' => builder.write_string("\\\\")
      '\n' => builder.write_string("\\n")
      '\r' => builder.write_string("\\r")
      '\t' => builder.write_string("\\t")
      _ => builder.write_char(ch)
    }
  }
  builder.write_char('"')
  builder.to_string()
}

///|
fn requires_dotenv_quotes(value : String) -> Bool {
  if value.length() == 0 {
    return true
  }
  for ch in value {
    match ch {
      ' ' | '\n' | '\r' | '\t' | '"' | '\'' | '#' | '=' | '\\' => return true
      _ => ()
    }
  }
  false
}

///|
fn summary_text(source : String) -> String {
  let builder = StringBuilder::new()
  for ch in source {
    match ch {
      '\n' | '\r' | '\t' => builder.write_char(' ')
      _ => builder.write_char(ch)
    }
  }
  let sanitized = builder.to_string().trim().to_owned()
  if sanitized.length() == 0 {
    "-"
  } else {
    sanitized
  }
}
