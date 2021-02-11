module FacebookAuthentication
  extend ActiveSupport::Concern

  def setup_facebook
    # pages_manage_metadata is for Facebook API > 7
    # manage_pages is for Facebook API < 7
    # An error will be displayed for Facebook users that are admins of the Facebook app, but should be transparent for other users
    request.env['omniauth.strategy'].options[:scope] = 'pages_manage_metadata,manage_pages,pages_messaging' if params[:context] == 'smooch'
  end

  # OAuth callback
  def facebook
    request.env['omniauth.auth']['url'] = 'https://facebook.com/' + request.env['omniauth.auth'].uid
    start_session_and_redirect
  end
end
