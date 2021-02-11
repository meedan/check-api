module TwitterAuthentication
  extend ActiveSupport::Concern

  def setup_twitter
    prefix = params[:context].to_s == 'smooch' ? 'smooch_' : ''
    request.env['omniauth.strategy'].options[:consumer_key] = CheckConfig.get("#{prefix}twitter_consumer_key")
    request.env['omniauth.strategy'].options[:consumer_secret] = CheckConfig.get("#{prefix}twitter_consumer_secret")
  end

  # OAuth callback
  def twitter
    request.env['omniauth.auth']['url'] = 'https://twitter.com/' + request.env['omniauth.auth'].info.nickname
    start_session_and_redirect
  end
end
