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
  let kind = metric_kind(registry, name, labels)
  with_metric(registry, { name, kind, labels, value: current + delta })
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
/// Looks up one metric kind by name and labels, defaulting to counters.
fn metric_kind(
  registry : MetricsRegistry,
  name : String,
  labels : Array[(String, String)],
) -> MetricKind {
  for sample in registry.samples {
    if sample.name == name && sample.labels == labels {
      return sample.kind
    }
  }
  CounterMetric
}

///|
/// Renders metrics in Prometheus exposition format.
pub fn render_prometheus(registry : MetricsRegistry) -> String {
  let lines : Array[String] = []
  let described_names : Array[String] = []
  for sample in registry.samples {
    let metric_name = prometheus_metric_name(sample.name)
    if !described_names.contains(metric_name) {
      let kind = match sample.kind {
        CounterMetric => "counter"
        GaugeMetric => "gauge"
      }
      lines.push("# TYPE " + metric_name + " " + kind)
      described_names.push(metric_name)
    }
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
      parts.push(
        prometheus_label_name(label.0) + "=" + @support.json_string(label.1),
      )
    }
    "{" + parts.join(",") + "}"
  }
  prometheus_metric_name(sample.name) + labels + " " + sample.value.to_string()
}

///|
fn prometheus_metric_name(source : String) -> String {
  sanitize_prometheus_identifier(source, allow_colon=true)
}

///|
fn prometheus_label_name(source : String) -> String {
  sanitize_prometheus_identifier(source, allow_colon=false)
}

///|
fn sanitize_prometheus_identifier(
  source : String,
  allow_colon~ : Bool,
) -> String {
  if source.length() == 0 {
    return "_"
  }
  let builder = StringBuilder::new()
  let mut first = true
  for ch in source {
    if first {
      if is_prometheus_initial_char(ch, allow_colon~) {
        builder.write_char(ch)
      } else if is_prometheus_identifier_char(ch, allow_colon~) {
        builder.write_char('_')
        builder.write_char(ch)
      } else {
        builder.write_char('_')
      }
      first = false
    } else if is_prometheus_identifier_char(ch, allow_colon~) {
      builder.write_char(ch)
    } else {
      builder.write_char('_')
    }
  }
  builder.to_string()
}

///|
fn is_prometheus_initial_char(ch : Char, allow_colon~ : Bool) -> Bool {
  (ch >= 'A' && ch <= 'Z') ||
  (ch >= 'a' && ch <= 'z') ||
  ch == '_' ||
  (allow_colon && ch == ':')
}

///|
fn is_prometheus_identifier_char(ch : Char, allow_colon~ : Bool) -> Bool {
  is_prometheus_initial_char(ch, allow_colon~) || (ch >= '0' && ch <= '9')
}
