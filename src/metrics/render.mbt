///|
/// Adds or replaces one metric sample in a registry.
pub fn with_metric(
  registry : MetricsRegistry,
  sample : MetricSample,
) -> MetricsRegistry {
  let samples : Array[MetricSample] = []
  for current in registry.samples {
    if current.name != sample.name || current.labels != sample.labels {
      samples.push(current)
    }
  }
  samples.push(sample)
  { samples, }
}

///|
/// Increments a counter or gauge-like metric.
pub fn increment_metric(
  registry : MetricsRegistry,
  name : String,
  labels : Array[(String, String)],
  delta : Int,
) -> MetricsRegistry {
  let current = metric_value(registry, name, labels)
  with_metric(registry, counter(name, labels, current + delta))
}

///|
/// Sets a gauge value in a registry.
pub fn set_metric(
  registry : MetricsRegistry,
  name : String,
  labels : Array[(String, String)],
  value : Int,
) -> MetricsRegistry {
  with_metric(registry, gauge(name, labels, value))
}

///|
/// Looks up one metric value by name and labels.
pub fn metric_value(
  registry : MetricsRegistry,
  name : String,
  labels : Array[(String, String)],
) -> Int {
  for sample in registry.samples {
    if sample.name == name && sample.labels == labels {
      return sample.value
    }
  }
  0
}

///|
/// Renders metrics in Prometheus exposition format.
pub fn render_prometheus(registry : MetricsRegistry) -> String {
  let lines : Array[String] = []
  for sample in registry.samples {
    let kind = match sample.kind {
      CounterMetric => "counter"
      GaugeMetric => "gauge"
    }
    lines.push("# TYPE " + sample.name + " " + kind)
    lines.push(render_sample(sample))
  }
  lines.join("\n")
}

///|
/// Renders one registry in a CLI-friendly format.
pub fn metrics_summary(registry : MetricsRegistry) -> String {
  let lines : Array[String] = []
  for sample in registry.samples {
    lines.push(render_sample(sample))
  }
  lines.join("\n")
}

///|
/// Renders one metric sample in Prometheus line format.
fn render_sample(sample : MetricSample) -> String {
  let labels = if sample.labels.is_empty() {
    ""
  } else {
    let parts : Array[String] = []
    for label in sample.labels {
      parts.push(label.0 + "=" + @support.json_string(label.1))
    }
    "{" + parts.join(",") + "}"
  }
  sample.name + labels + " " + sample.value.to_string()
}
