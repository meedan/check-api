module GoogleAuthentication
  extend ActiveSupport::Concern

  # OAuth callback
  def google_oauth2
    request.env['omniauth.auth']['url'] = 'https://www.googleapis.com/plus/v1/people/' + request.env['omniauth.auth'].uid
    start_session_and_redirect
  end
end
