///|
/// mbt on rails
///
/// A Rails-inspired MoonBit framework with:
/// - src-based packages
/// - resources / namespace router DSL
/// - Active Record-like schema, validations, associations, callbacks
/// - reversible migrations
/// - authentication, sessions, policy checks, csrf helpers
/// - Vapor Moon compatible pages, layouts, loaders, islands, server actions
/// - scaffold generation for resource-oriented apps

///|
pub using @support {
  type MbtvPath,
  append_entries,
  classify,
  clone_array,
  entries_to_json,
  escape_html,
  find_entry,
  hash_string,
  join_path_segments,
  json_string,
  mbtv_path,
  normalize_path,
  singularize,
  split_path,
}

///|
pub using @http {
  type HttpMethod,
  type MatchedRoute,
  type Request,
  type ResourceOptions,
  type Response,
  type ResponseBody,
  type RoutePattern,
  type RouteSegment,
  type RouteSpec,
  all_http_methods,
  build_path,
  default_resource_options,
  http_delete,
  http_get,
  http_head,
  http_options,
  http_patch,
  http_post,
  http_put,
  json_response,
  match_route,
  namespace_routes,
  no_content_response,
  not_found_response,
  ok_html,
  ok_json,
  ok_text,
  parse_route_pattern,
  recognize,
  redirect_response,
  render_response_body,
  request,
  resources,
  route,
  scope_routes,
  with_collection_action,
  with_member_action,
  with_only,
  with_param_name,
}

///|
pub using @auth {
  type AuthConfig,
  type AuthCookie,
  type AuthRequirement,
  type EmailVerificationToken,
  type Identity,
  type PasswordResetToken,
  type PolicyRule,
  type Session,
  allowed,
  auth_guest_only,
  auth_public,
  auth_required,
  auth_summary,
  authorize,
  cookie_header,
  csrf_valid,
  default_auth_config,
  digest_password,
  identity,
  issue_email_verification,
  issue_password_reset,
  issue_session,
  permission_access,
  policy_rule,
  render_auth_requirement,
  role_access,
  session_cookie,
  verify_password,
}
