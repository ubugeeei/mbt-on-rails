///|
/// Extra Rails-style surfaces that keep the main facade compact.

///|
pub using @controller {
  deliver_mail_step,
  enqueue_job_step,
  permit_params_step,
  touch_cache_step,
}

///|
pub using @params {
  type Parameters,
  type PermittedParams,
  merge_params,
  param_value,
  params,
  permit,
  permit_scope,
  permitted_attributes,
  permitted_summary,
  permitted_value,
  require_scope,
}

///|
pub using @job {
  type DrainedJobs,
  type EnqueuedJob,
  type JobDefinition,
  type JobQueue,
  drain_ready,
  enqueue_at,
  enqueue_now,
  enqueued_job,
  job,
  job_queue,
  job_ready,
  job_summary,
  retry_job,
}

///|
pub using @mailer {
  type MailDelivery,
  type MailTemplate,
  type MailerDefinition,
  compose_mail,
  delivery_job,
  enqueue_delivery,
  mail_template,
  mailer,
  mailer_summary,
  with_bcc,
  with_cc,
}

///|
pub using @cache {
  type CacheEntry,
  type CacheFetchResult,
  type CacheStore,
  cache_delete,
  cache_delete_tag,
  cache_fetch,
  cache_key,
  cache_read,
  cache_store,
  cache_summary,
  cache_write,
}
