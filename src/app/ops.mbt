///|
/// Renders the configured middleware stack in a CLI-friendly format.
pub fn MbtOnRailsApp::middleware_table(self : MbtOnRailsApp) -> String {
  @middleware.middleware_summary(self.middlewares)
}

///|
/// Renders the configured fixtures in a CLI-friendly format.
pub fn MbtOnRailsApp::fixture_table(self : MbtOnRailsApp) -> String {
  let blocks : Array[String] = []
  for fixture in self.fixtures {
    blocks.push(@fixture.fixture_summary(fixture))
  }
  blocks.join("\n")
}

///|
/// Renders the configured seeds in a CLI-friendly format.
pub fn MbtOnRailsApp::seed_table(self : MbtOnRailsApp) -> String {
  let blocks : Array[String] = []
  for seed in self.seeds {
    blocks.push(@fixture.seed_summary(seed))
  }
  blocks.join("\n")
}

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
