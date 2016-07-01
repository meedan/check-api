module FacebookAuthentication
  extend ActiveSupport::Concern

  # OAuth callback
  def facebook
    destination = '/api'
    if request.env.has_key?('omniauth.params')
      destination = request.env['omniauth.params']['destination'] unless request.env['omniauth.params']['destination'].blank?
    end
    request.env['omniauth.auth']['url'] = 'https://facebook.com/' + request.env['omniauth.auth'].uid
    start_session_and_redirect(destination)
  end
end
