module FacebookAuthentication
  extend ActiveSupport::Concern

  def setup_facebook
    # pages_manage_metadata is for Facebook API > 7
    # manage_pages is for Facebook API < 7
    # An error will be displayed for Facebook users that are admins of the Facebook app, but should be transparent for other users
    request.env['omniauth.strategy'].options[:scope] = 'pages_show_list,pages_read_engagement,pages_manage_metadata,pages_messaging,instagram_manage_messages,instagram_basic,pages_utility_messaging' if params[:context] == 'smooch'
    prefix = facebook_context == 'smooch' ? 'smooch_' : ''
    request.env['omniauth.strategy'].options[:client_id] = CheckConfig.get("#{prefix}facebook_app_id")
    request.env['omniauth.strategy'].options[:client_secret] = CheckConfig.get("#{prefix}facebook_app_secret")
  end

  def facebook_context
    return params[:context] if params[:context]
    session['omniauth.params'] ? session['omniauth.params']['context'] : nil
  end

  # OAuth callback
  def facebook
    Rails.logger.info "FacebookAuthentication-facebook:oauthcallback:: #{request.env['omniauth.auth'].to_json}"
    request.env['omniauth.auth']['url'] = 'https://facebook.com/' + request.env['omniauth.auth'].uid
    start_session_and_redirect
  end
end
