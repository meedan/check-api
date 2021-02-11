class Api::V1::AdminController < Api::V1::BaseApiController
  before_filter :authenticate_from_token!, except: [:add_publisher_to_project, :save_twitter_credentials_for_smooch_bot, :save_facebook_credentials_for_smooch_bot]

  # GET /api/admin/project/add_publisher?token=:project-token
  def add_publisher_to_project
    project = Project.find(params[:id])
    provider = params[:provider]
    auth = session["check.#{provider}.authdata"]
    if params[:token].to_s == project.token
      setting = (project.get_social_publishing || {}).clone
      setting[provider] = auth
      project.set_social_publishing(setting)
      project.skip_check_ability = true
      project.save!
      render text: I18n.t(:auto_publisher_added_to_project, project: project.title, provider: provider.capitalize)
    else
      render text: I18n.t(:invalid_token), status: 401
    end
  end

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
      app_id = tbi.get_smooch_app_id
      Bot::Smooch.get_installation('smooch_app_id', app_id)
      api_client = Bot::Smooch.smooch_api_client
      api_instance = SmoochApi::IntegrationApi.new(api_client)
      params = {
        'type' => 'twitter',
        'tier' => CheckConfig.get('smooch_twitter_tier'),
        'envName' => CheckConfig.get('smooch_twitter_env_name'),
        'consumerKey' => CheckConfig.get('smooch_twitter_consumer_key'),
        'consumerSecret' => CheckConfig.get('smooch_twitter_consumer_secret'),
        'accessTokenKey' => auth['token'],
        'accessTokenSecret' => auth['secret'],
        'displayName' => 'Twitter'
      }
      body = SmoochApi::IntegrationCreate.new(params)
      api_instance.create_integration(app_id, body)
      @message = I18n.t(:smooch_twitter_success)
      status = 200
    else
      @message = I18n.t(:invalid_token)
      status = 401
    end
    render template: 'message', formats: :html, status: status
  end

  # GET /api/admin/smooch_bot/:bot-installation-id/authorize/facebook?token=:bot-installation-token
  def save_facebook_credentials_for_smooch_bot
    tbi = TeamBotInstallation.find(params[:id])
    auth = session['check.facebook.authdata']
    status = nil
    if params[:token].to_s.gsub('#_=_', '') == tbi.get_smooch_authorization_token
      response = Net::HTTP.get_response(URI("https://graph.facebook.com/me/accounts?client_id=#{CheckConfig.get('facebook_app_id')}&client_secret=#{CheckConfig.get('facebook_app_secret')}&access_token=#{auth['token']}&limit=100"))
      pages = JSON.parse(response.body)['data']
      if pages.size != 1
        @message = I18n.t(:must_select_exactly_one_facebook_page)
        status = 400
      else
        app_id = tbi.get_smooch_app_id
        Bot::Smooch.get_installation('smooch_app_id', app_id)
        api_client = Bot::Smooch.smooch_api_client
        api_instance = SmoochApi::IntegrationApi.new(api_client)
        params = {
          'type' => 'messenger',
          'displayName' => 'Facebook',
          'appId' => CheckConfig.get('facebook_app_id'),
          'appSecret' => CheckConfig.get('facebook_app_secret'),
          'pageAccessToken' => pages[0]['access_token']
        }
        body = SmoochApi::IntegrationCreate.new(params)
        api_instance.create_integration(app_id, body)
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
