///|
/// Declares one Action Cable-style channel.
pub struct CableChannel {
  name : String
  stream_name : String
  topic_fields : Array[String]
}

///|
/// Represents one broadcast payload sent to a channel stream.
pub struct CableBroadcast {
  channel_name : String
  stream_name : String
  payload : String
  content_type : String
}

///|
/// Builds one cable channel definition.
pub fn cable_channel(
  name : String,
  stream_name : String,
  topic_fields : Array[String],
) -> CableChannel {
  { name, stream_name, topic_fields }
}

///|
/// Builds one generic broadcast payload.
pub fn cable_broadcast(
  channel : CableChannel,
  payload : String,
  content_type : String,
) -> CableBroadcast {
  {
    channel_name: channel.name,
    stream_name: channel.stream_name,
    payload,
    content_type,
  }
}

///|
/// Builds one Turbo Stream broadcast payload.
pub fn broadcast_turbo(
  channel : CableChannel,
  streams : Array[@turbo.TurboStream],
) -> CableBroadcast {
  cable_broadcast(
    channel,
    @turbo.render_turbo_stream(streams),
    "text/vnd.turbo-stream.html; charset=utf-8",
  )
}
