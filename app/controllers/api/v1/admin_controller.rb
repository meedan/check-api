class Api::V1::AdminController < Api::V1::BaseApiController
  before_action :authenticate_from_token!, except: [:save_twitter_credentials_for_smooch_bot, :save_messenger_credentials_for_smooch_bot, :save_instagram_credentials_for_smooch_bot]

  # GET /api/admin/user/slack?uid=:uid
  def slack_user
    user = User.find_with_omniauth(params[:uid].to_s, 'slack')
    slack_account = user.accounts.where(provider: 'slack').first unless user.nil?
    user = { token: slack_account.token } unless slack_account.nil?
    user = nil unless @key.bot_user.nil? # Allow global API keys only
    render_user user, 'slack_uid'
  end

  # GET /api/admin/smooch_bot/:bot-installation-id/authorize/twitter?token=:bot-installation-token
  def save_twitter_credentials_for_smooch_bot
    tbi = TeamBotInstallation.find(params[:id])
    auth = session['check.twitter.authdata']
    status = nil
    if params[:token].to_s == tbi.get_smooch_authorization_token
      params = {
        'tier' => CheckConfig.get('smooch_twitter_tier'),
        'envName' => CheckConfig.get('smooch_twitter_env_name'),
        'consumerKey' => CheckConfig.get('smooch_twitter_consumer_key'),
        'consumerSecret' => CheckConfig.get('smooch_twitter_consumer_secret'),
        'accessTokenKey' => auth['token'],
        'accessTokenSecret' => auth['secret']
      }
      tbi.smooch_add_integration('twitter', params)
      @message = I18n.t(:smooch_twitter_success)
      status = 200
    else
      @message = I18n.t(:invalid_token)
      status = 401
    end
    render template: 'message', formats: :html, status: status
  end

  # GET /api/admin/smooch_bot/:bot-installation-id/authorize/messenger?token=:bot-installation-token
  def save_messenger_credentials_for_smooch_bot
    self.save_facebook_credentials_for_smooch_bot('messenger')
  end

  # GET /api/admin/smooch_bot/:bot-installation-id/authorize/instagram?token=:bot-installation-token
  def save_instagram_credentials_for_smooch_bot
    self.save_facebook_credentials_for_smooch_bot('instagram')
  end

  private

  def save_facebook_credentials_for_smooch_bot(platform) # "platform" is either "instagram" or "messenger"
    tbi = TeamBotInstallation.find(params[:id])
    auth = session['check.facebook.authdata']
    status = nil
    if auth.blank?
      status = 400
      @message = I18n.t(:invalid_facebook_authdata)
      error_msg = StandardError.new('Could not authenticate Facebook account for tipline Messenger integration.')
      CheckSentry.notify(error_msg, team_bot_installation_id: tbi.id, platform: platform)
    elsif params[:token].to_s.gsub('#_=_', '') == tbi.get_smooch_authorization_token
      q_params = {
        client_id: CheckConfig.get('smooch_facebook_app_id'),
        client_secret: CheckConfig.get('smooch_facebook_app_secret'),
        access_token: auth['token'],
        limit: 100,
      }
      response = Net::HTTP.get_response(URI("https://graph.facebook.com/me/accounts?#{q_params.to_query}"))
      pages = JSON.parse(response.body)['data']
      if pages.size != 1
        Rails.logger.info("[Facebook Messenger Integration] API scoped token: #{auth['token']} API response: #{response.body}")
        CheckSentry.notify(StandardError.new('Unexpected list of Facebook pages returned for tipline Messenger integration'), team_bot_installation_id: tbi.id, response: response.body)
        @message = I18n.t(:must_select_exactly_one_facebook_page)
        status = 400
      else
        params = {
          'appId' => CheckConfig.get('smooch_facebook_app_id'),
          'appSecret' => CheckConfig.get('smooch_facebook_app_secret'),
          'pageAccessToken' => pages[0]['access_token']
        }
        tbi.smooch_add_integration(platform, params)
        @message = I18n.t(:smooch_facebook_success)
        status = 200
      end
    else
      @message = I18n.t(:invalid_token)
      status = 401
    end
    render template: 'message', formats: :html, status: status
  end
end
