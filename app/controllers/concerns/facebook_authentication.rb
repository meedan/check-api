module FacebookAuthentication
  extend ActiveSupport::Concern

  # OAuth callback
  def facebook
    request.env['omniauth.auth']['url'] = 'https://facebook.com/' + request.env['omniauth.auth'].uid
    start_session_and_redirect
  end
end
