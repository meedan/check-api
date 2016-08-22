module SlackAuthentication
  extend ActiveSupport::Concern

  # OAuth callback
  def slack
    destination = '/api'
    if request.env.has_key?('omniauth.params')
      destination = request.env['omniauth.params']['destination'] unless request.env['omniauth.params']['destination'].blank?
    end
    start_session_and_redirect(destination)
  end
end
