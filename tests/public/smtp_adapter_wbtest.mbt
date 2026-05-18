///|
fn sample_delivery() -> MailDelivery {
  {
    mailer_name: "UserMailer",
    action_name: "welcome",
    from: "noreply@example.com",
    to: ["alice@example.com"],
    cc: [],
    bcc: [],
    subject: "Welcome",
    assigns: [],
  }
}

///|
test "null_smtp_adapter always reports connection_failed" {
  let adapter = null_smtp_adapter()
  assert_eq(smtp_adapter_summary(adapter), "smtp_adapter name=null")
  match smtp_deliver(adapter, sample_delivery()) {
    SmtpDelivered(_) => assert_true(false)
    SmtpDeliveryFailed(error) =>
      assert_eq(
        smtp_adapter_error_message(error),
        "connection_failed: null adapter is offline",
      )
  }
  match smtp_verify(adapter) {
    SmtpDelivered(_) => assert_true(false)
    SmtpDeliveryFailed(error) =>
      assert_eq(
        smtp_adapter_error_message(error),
        "connection_failed: null adapter is offline",
      )
  }
  match smtp_close(adapter) {
    SmtpDelivered(_) => assert_true(true)
    SmtpDeliveryFailed(_) => assert_true(false)
  }
}

///|
test "smtp_adapter_error_message renders every variant for diagnostics" {
  assert_eq(
    smtp_adapter_error_message(SmtpConnectionFailed("broken")),
    "connection_failed: broken",
  )
  assert_eq(
    smtp_adapter_error_message(SmtpAuthenticationFailed("bad creds")),
    "authentication_failed: bad creds",
  )
  assert_eq(
    smtp_adapter_error_message(SmtpRecipientRejected("no mailbox")),
    "recipient_rejected: no mailbox",
  )
  assert_eq(
    smtp_adapter_error_message(SmtpRateLimited("too fast")),
    "rate_limited: too fast",
  )
  assert_eq(smtp_adapter_error_message(SmtpOtherError("misc")), "other: misc")
}

///|
test "captured_smtp_adapter records every send into the shared counter" {
  let counter : Array[Int] = []
  let adapter = captured_smtp_adapter(counter)
  match smtp_deliver(adapter, sample_delivery()) {
    SmtpDelivered(id) => assert_true(id == Some("captured-1"))
    SmtpDeliveryFailed(_) => assert_true(false)
  }
  match smtp_deliver(adapter, sample_delivery()) {
    SmtpDelivered(id) => assert_true(id == Some("captured-2"))
    SmtpDeliveryFailed(_) => assert_true(false)
  }
  assert_eq(counter[0], 2)
}

///|
test "smtp_adapter composes a fake driver for round-trip tests" {
  let fail_step : Bool = false
  let deliver = fn(_mail : MailDelivery) -> SmtpDeliveryOutcome {
    if fail_step {
      SmtpDeliveryFailed(SmtpRecipientRejected("rejected"))
    } else {
      SmtpDelivered(Some("fake-msg-id"))
    }
  }
  let no_op = fn() -> SmtpDeliveryOutcome { SmtpDelivered(None) }
  let adapter = smtp_adapter("fake", deliver, no_op, no_op)
  assert_eq(smtp_adapter_summary(adapter), "smtp_adapter name=fake")
  match smtp_deliver(adapter, sample_delivery()) {
    SmtpDelivered(id) => assert_true(id == Some("fake-msg-id"))
    SmtpDeliveryFailed(_) => assert_true(false)
  }
}
