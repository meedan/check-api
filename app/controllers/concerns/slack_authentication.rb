module SlackAuthentication
  extend ActiveSupport::Concern

  # OAuth callback
  def slack
    info = request.env['omniauth.auth']['extra']['raw_info']
    request.env['omniauth.auth']['url'] = info['url'] + 'team/' + info['user']
    start_session_and_redirect
  end
end
