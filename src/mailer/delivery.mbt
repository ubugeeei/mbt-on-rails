///|
/// Composes one outgoing message from a mailer/action pair.
pub fn compose_mail(
  mailer : MailerDefinition,
  action_name : String,
  to : Array[String],
  assigns : Array[(String, String)],
) -> MailDelivery? {
  for template in mailer.templates {
    if template.action_name == action_name {
      return Some({
        mailer_name: mailer.name,
        action_name,
        from: mailer.from,
        to,
        cc: [],
        bcc: [],
        subject: template.subject,
        assigns,
      })
    }
  }
  None
}

///|
/// Returns a delivery with extra CC recipients attached.
pub fn with_cc(delivery : MailDelivery, cc : Array[String]) -> MailDelivery {
  { ..delivery, cc: @support.clone_array(cc) }
}

///|
/// Returns a delivery with extra BCC recipients attached.
pub fn with_bcc(delivery : MailDelivery, bcc : Array[String]) -> MailDelivery {
  { ..delivery, bcc: @support.clone_array(bcc) }
}

///|
/// Converts one delivery into an enqueued background job.
pub fn delivery_job(
  delivery : MailDelivery,
  queue_name : String,
  run_at : String?,
) -> @job.EnqueuedJob {
  let definition = mail_delivery_definition(delivery, queue_name)
  @job.enqueued_job(
    definition,
    delivery_payload(delivery),
    match run_at {
      Some(timestamp) => timestamp
      None => ""
    },
    0,
  )
}

///|
/// Enqueues one delivery into a job queue.
pub fn enqueue_delivery(
  queue : @job.JobQueue,
  delivery : MailDelivery,
  run_at : String?,
) -> @job.JobQueue {
  let definition = mail_delivery_definition(delivery, queue.name)
  match run_at {
    Some(timestamp) =>
      @job.enqueue_at(queue, definition, delivery_payload(delivery), timestamp)
    None => @job.enqueue_now(queue, definition, delivery_payload(delivery))
  }
}

///|
/// Renders one mailer in a compact summary format.
pub fn mailer_summary(mailer : MailerDefinition) -> String {
  let lines : Array[String] = ["mailer " + mailer.name + " from=" + mailer.from]
  for template in mailer.templates {
    lines.push(
      "  - " +
      template.action_name +
      " subject=" +
      template.subject +
      " html=" +
      template.html_path,
    )
  }
  lines.join("\n")
}

///|
/// Converts a delivery into flat job payload fields.
fn delivery_payload(delivery : MailDelivery) -> Array[(String, String)] {
  [
    ("mailer_name", delivery.mailer_name),
    ("action_name", delivery.action_name),
    ("to", delivery.to.join(",")),
    ("cc", delivery.cc.join(",")),
    ("bcc", delivery.bcc.join(",")),
    ("subject", delivery.subject),
    ("assigns", @support.entries_to_json(delivery.assigns)),
  ]
}

///|
/// Builds the canonical Active Job wrapper used for mail delivery.
fn mail_delivery_definition(
  delivery : MailDelivery,
  queue_name : String,
) -> @job.JobDefinition {
  @job.job(
    "mailers.deliver",
    queue_name,
    [
      ("mailer_name", "String"),
      ("action_name", "String"),
      ("to", "String"),
      ("subject", "String"),
    ],
    5,
    Some("mail:" + delivery.mailer_name + ":" + delivery.action_name),
  )
}
