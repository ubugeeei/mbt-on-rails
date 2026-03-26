///|
/// Composes one mail delivery and records a Rails-style process event.
pub fn compose_mail_with_notifications(
  mailer~ : MailerDefinition,
  action_name~ : String,
  to~ : Array[String],
  assigns~ : Array[(String, String)],
  notifications~ : @support.Notifications,
) -> (MailDelivery?, @support.Notifications) {
  let delivery = compose_mail(mailer, action_name, to, assigns)
  let found = match delivery {
    Some(_) => "true"
    None => "false"
  }
  let updated = notifications.instrument(name="process.action_mailer", payload=[
    ("mailer", mailer.name),
    ("action", action_name),
    ("found", found),
    ("recipient_count", to.length().to_string()),
  ])
  (delivery, updated)
}

///|
/// Enqueues one mail delivery and records Active Job enqueue events.
pub fn enqueue_delivery_with_notifications(
  queue~ : @job.JobQueue,
  delivery~ : MailDelivery,
  run_at~ : String?,
  notifications~ : @support.Notifications,
) -> (@job.JobQueue, @support.Notifications) {
  let definition = mail_delivery_definition(delivery, queue.name)
  match run_at {
    Some(timestamp) =>
      @job.enqueue_at_with_notifications(
        queue~,
        definition~,
        payload=delivery_payload(delivery),
        run_at=timestamp,
        notifications~,
      )
    None =>
      @job.enqueue_now_with_notifications(
        queue~,
        definition~,
        payload=delivery_payload(delivery),
        notifications~,
      )
  }
}
