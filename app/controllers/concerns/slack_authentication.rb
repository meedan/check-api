module SlackAuthentication
  extend ActiveSupport::Concern

  # OAuth callback
  def slack
    request.env['omniauth.auth']['url'] = 'https://slack.com/'
    start_session_and_redirect(params[:destination])
  end
end
