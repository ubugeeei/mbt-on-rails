///|
/// Renders the configured job queues in a CLI-friendly format.
pub fn MbtOnRailsApp::job_table(self : MbtOnRailsApp) -> String {
  let blocks : Array[String] = []
  for queue in self.job_queues {
    blocks.push(@job.job_summary(queue))
  }
  blocks.join("\n\n")
}

///|
/// Renders the configured mailers in a CLI-friendly format.
pub fn MbtOnRailsApp::mailer_table(self : MbtOnRailsApp) -> String {
  let blocks : Array[String] = []
  for mailer in self.mailers {
    blocks.push(@mailer.mailer_summary(mailer))
  }
  blocks.join("\n\n")
}

///|
/// Renders the configured cache namespaces in a CLI-friendly format.
pub fn MbtOnRailsApp::cache_table(self : MbtOnRailsApp) -> String {
  let blocks : Array[String] = []
  for store in self.caches {
    blocks.push(@cache.cache_summary(store))
  }
  blocks.join("\n\n")
}
