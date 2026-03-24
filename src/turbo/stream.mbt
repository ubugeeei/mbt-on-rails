///|
/// Lists the Turbo Stream operations supported by the framework.
pub enum TurboStreamAction {
  Append
  Prepend
  Replace
  Update
  Remove
  Before
  After
} derive(Eq, Show)

///|
/// Represents one Turbo Stream message.
pub struct TurboStream {
  action : TurboStreamAction
  target : String
  html : String
}

///|
/// Builds one Turbo Stream message.
pub fn turbo_stream(
  action : TurboStreamAction,
  target : String,
  html : String,
) -> TurboStream {
  { action, target, html }
}

///|
/// Builds an append stream.
pub fn append_stream(target : String, html : String) -> TurboStream {
  turbo_stream(Append, target, html)
}

///|
/// Builds a prepend stream.
pub fn prepend_stream(target : String, html : String) -> TurboStream {
  turbo_stream(Prepend, target, html)
}

///|
/// Builds a replace stream.
pub fn replace_stream(target : String, html : String) -> TurboStream {
  turbo_stream(Replace, target, html)
}

///|
/// Builds an update stream.
pub fn update_stream(target : String, html : String) -> TurboStream {
  turbo_stream(Update, target, html)
}

///|
/// Builds a remove stream.
pub fn remove_stream(target : String) -> TurboStream {
  turbo_stream(Remove, target, "")
}

///|
/// Builds an insert-before stream.
pub fn before_stream(target : String, html : String) -> TurboStream {
  turbo_stream(Before, target, html)
}

///|
/// Builds an insert-after stream.
pub fn after_stream(target : String, html : String) -> TurboStream {
  turbo_stream(After, target, html)
}

///|
/// Renders many Turbo Stream messages into one response body.
pub fn render_turbo_stream(streams : Array[TurboStream]) -> String {
  let chunks : Array[String] = []
  for stream in streams {
    let body = if stream.action == Remove {
      ""
    } else {
      "<template>" + stream.html + "</template>"
    }
    chunks.push(
      "<turbo-stream action=\"" +
      @support.escape_html(render_action(stream.action)) +
      "\" target=\"" +
      @support.escape_html(stream.target) +
      "\">" +
      body +
      "</turbo-stream>",
    )
  }
  chunks.join("")
}

///|
/// Builds a Turbo Stream HTTP response.
pub fn ok_turbo_stream(streams : Array[TurboStream]) -> @http.Response {
  @http.typed_text_response(
    200,
    "text/vnd.turbo-stream.html; charset=utf-8",
    render_turbo_stream(streams),
  )
}

///|
/// Renders a Turbo Stream action name.
fn render_action(action : TurboStreamAction) -> String {
  match action {
    Append => "append"
    Prepend => "prepend"
    Replace => "replace"
    Update => "update"
    Remove => "remove"
    Before => "before"
    After => "after"
  }
}
