///|
/// Hydrates the request session id from the configured session cookies.
fn prepare_request_for_auth(
  request : @http.Request,
  config : @auth.AuthConfig,
) -> @http.Request {
  @http.with_request_session(
    request,
    store=@auth.session_store_for_config(config~, remember_me=false),
    fallback_store=Some(
      @auth.session_store_for_config(config~, remember_me=true),
    ),
  )
}
