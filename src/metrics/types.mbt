///|
/// Lists the metric kinds supported by the framework.
pub enum MetricKind {
  CounterMetric
  GaugeMetric
} derive(Eq, Show)

///|
/// Represents one named metric sample.
pub struct MetricSample {
  name : String
  kind : MetricKind
  labels : Array[(String, String)]
  value : Int
}

///|
/// Stores the metrics collected for one process.
pub struct MetricsRegistry {
  samples : Array[MetricSample]
}

///|
/// Builds an empty metrics registry.
pub fn metrics_registry() -> MetricsRegistry {
  { samples: [] }
}

///|
/// Builds one counter sample.
pub fn counter(
  name : String,
  labels : Array[(String, String)],
  value : Int,
) -> MetricSample {
  { name, kind: CounterMetric, labels, value }
}

///|
/// Builds one gauge sample.
pub fn gauge(
  name : String,
  labels : Array[(String, String)],
  value : Int,
) -> MetricSample {
  { name, kind: GaugeMetric, labels, value }
}
