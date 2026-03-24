///|
/// Renders one channel registry in a CLI-friendly format.
pub fn cable_summary(channels : Array[CableChannel]) -> String {
  let lines : Array[String] = []
  for channel in channels {
    lines.push(
      channel.name +
      " stream=" +
      channel.stream_name +
      " topics=[" +
      channel.topic_fields.join(", ") +
      "]",
    )
  }
  lines.join("\n")
}

///|
/// Renders one broadcast in a CLI-friendly format.
pub fn broadcast_summary(broadcast : CableBroadcast) -> String {
  "broadcast " +
  broadcast.channel_name +
  " -> " +
  broadcast.stream_name +
  " type=" +
  broadcast.content_type +
  " payload=" +
  @support.json_string(broadcast.payload)
}
