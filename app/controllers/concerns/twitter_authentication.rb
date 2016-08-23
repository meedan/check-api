module TwitterAuthentication
  extend ActiveSupport::Concern

  # OAuth callback
  def twitter
    request.env['omniauth.auth']['url'] = 'https://twitter.com/' + request.env['omniauth.auth'].info.nickname
    start_session_and_redirect
  end
end
