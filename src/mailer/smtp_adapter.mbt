///|
/// Errors raised by an SMTP delivery adapter.
pub(all) enum SmtpAdapterError {
  SmtpConnectionFailed(String)
  SmtpAuthenticationFailed(String)
  SmtpRecipientRejected(String)
  SmtpRateLimited(String)
  SmtpOtherError(String)
}

///|
/// Renders an SMTP error as a CLI-friendly diagnostic string.
pub fn smtp_adapter_error_message(error : SmtpAdapterError) -> String {
  match error {
    SmtpConnectionFailed(detail) => "connection_failed: " + detail
    SmtpAuthenticationFailed(detail) => "authentication_failed: " + detail
    SmtpRecipientRejected(detail) => "recipient_rejected: " + detail
    SmtpRateLimited(detail) => "rate_limited: " + detail
    SmtpOtherError(detail) => "other: " + detail
  }
}

///|
/// Outcome of an SMTP send. Successful sends carry the server-assigned
/// message id when one is available.
pub(all) enum SmtpDeliveryOutcome {
  SmtpDelivered(String?)
  SmtpDeliveryFailed(SmtpAdapterError)
}

///|
/// Pluggable contract for an SMTP delivery driver.
///
/// Function-valued fields mirror the shape of `DatabaseAdapter` in
/// `src/active_record/adapter.mbt` so concrete drivers (in-process
/// queue, SMTP relay, third-party API) can plug in uniformly.
pub(all) struct SmtpAdapter {
  name : String
  deliver : (MailDelivery) -> SmtpDeliveryOutcome
  verify : () -> SmtpDeliveryOutcome
  close : () -> SmtpDeliveryOutcome
}

///|
/// Builds an SMTP adapter from explicit function values.
pub fn smtp_adapter(
  name : String,
  deliver : (MailDelivery) -> SmtpDeliveryOutcome,
  verify : () -> SmtpDeliveryOutcome,
  close : () -> SmtpDeliveryOutcome,
) -> SmtpAdapter {
  { name, deliver, verify, close }
}

///|
/// Returns an adapter that always reports a `SmtpConnectionFailed`.
///
/// Useful as a placeholder during wiring and in tests that want to
/// verify the surrounding orchestration handles errors correctly
/// without standing up a real SMTP server.
pub fn null_smtp_adapter() -> SmtpAdapter {
  let fail = fn(_mail : MailDelivery) -> SmtpDeliveryOutcome {
    SmtpDeliveryFailed(SmtpConnectionFailed("null adapter is offline"))
  }
  let fail_no_arg = fn() -> SmtpDeliveryOutcome {
    SmtpDeliveryFailed(SmtpConnectionFailed("null adapter is offline"))
  }
  let close_self = fn() -> SmtpDeliveryOutcome { SmtpDelivered(None) }
  { name: "null", deliver: fail, verify: fail_no_arg, close: close_self }
}

///|
/// Returns an adapter that records every delivery into a shared counter
/// cell so integration tests can verify wiring without an external relay.
///
/// The returned adapter and the counter array share state — push the
/// counter into the closure once at construction time and read it back
/// after the test issues its sends.
pub fn captured_smtp_adapter(counter : Array[Int]) -> SmtpAdapter {
  if counter.is_empty() {
    counter.push(0)
  }
  let deliver = fn(_mail : MailDelivery) -> SmtpDeliveryOutcome {
    counter[0] = counter[0] + 1
    SmtpDelivered(Some("captured-" + counter[0].to_string()))
  }
  let verify = fn() -> SmtpDeliveryOutcome { SmtpDelivered(None) }
  let close = fn() -> SmtpDeliveryOutcome { SmtpDelivered(None) }
  { name: "captured", deliver, verify, close }
}

///|
/// Issues a delivery against an adapter.
pub fn smtp_deliver(
  adapter : SmtpAdapter,
  mail : MailDelivery,
) -> SmtpDeliveryOutcome {
  (adapter.deliver)(mail)
}

///|
/// Issues a connection-verification call against an adapter.
pub fn smtp_verify(adapter : SmtpAdapter) -> SmtpDeliveryOutcome {
  (adapter.verify)()
}

///|
/// Closes the adapter (releases any held connection or relay session).
pub fn smtp_close(adapter : SmtpAdapter) -> SmtpDeliveryOutcome {
  (adapter.close)()
}

///|
/// One-line summary of an SMTP adapter for CLI / diagnostics output.
pub fn smtp_adapter_summary(adapter : SmtpAdapter) -> String {
  "smtp_adapter name=" + adapter.name
}
