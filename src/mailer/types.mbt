///|
/// Describes one mailer action template.
pub struct MailTemplate {
  action_name : String
  subject : String
  html_path : @support.MbtvPath
  text_path : String?
}

///|
/// Declares one Action Mailer-style mailer.
pub struct MailerDefinition {
  name : String
  from : String
  layout_name : String?
  templates : Array[MailTemplate]
}

///|
/// Represents one composed outgoing message.
pub struct MailDelivery {
  mailer_name : String
  action_name : String
  from : String
  to : Array[String]
  cc : Array[String]
  bcc : Array[String]
  subject : String
  assigns : Array[(String, String)]
}

///|
/// Builds one mailer template descriptor.
pub fn mail_template(
  action_name : String,
  subject : String,
  html_path : @support.MbtvPath,
  text_path : String?,
) -> MailTemplate {
  { action_name, subject, html_path, text_path }
}

///|
/// Builds one mailer definition.
pub fn mailer(
  name : String,
  from : String,
  layout_name : String?,
  templates : Array[MailTemplate],
) -> MailerDefinition {
  { name, from, layout_name, templates }
}
