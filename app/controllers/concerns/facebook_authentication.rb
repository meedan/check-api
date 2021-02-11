module FacebookAuthentication
  extend ActiveSupport::Concern

  def setup_facebook
    request.env['omniauth.strategy'].options[:scope] = 'manage_pages,pages_messaging' if params[:context] == 'smooch'
  end

  # OAuth callback
  def facebook
    request.env['omniauth.auth']['url'] = 'https://facebook.com/' + request.env['omniauth.auth'].uid
    start_session_and_redirect
  end
end
