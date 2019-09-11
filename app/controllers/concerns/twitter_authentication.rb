module TwitterAuthentication
  extend ActiveSupport::Concern

  def setup
    prefix = params[:context].to_s == 'smooch' ? 'smooch_' : ''
    request.env['omniauth.strategy'].options[:consumer_key] = CONFIG["#{prefix}twitter_consumer_key"]
    request.env['omniauth.strategy'].options[:consumer_secret] = CONFIG["#{prefix}twitter_consumer_secret"]
    render text: 'Setup complete.', status: 404
  end

  # OAuth callback
  def twitter
    request.env['omniauth.auth']['url'] = 'https://twitter.com/' + request.env['omniauth.auth'].info.nickname
    start_session_and_redirect
  end
end
