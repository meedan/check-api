# $ rake check:smooch:create_twitter_integration[slug,twitterhandle,env,sandbox]
# References:
# - https://docs.smooch.io/guide/twitter/#using-the-integration-api
# - https://docs.smooch.io/guide/twitter/
# - https://docs.smooch.io/rest/#twitter-dm
namespace :check do
  namespace :smooch do
    desc 'Create a Twitter DM integration for a Smooch bot'
    task :create_twitter_integration, [:team_slug, :twitter_handle, :twitter_env_name, :twitter_tier] => :environment do |_t, args|
      
      account = Account.where(provider: 'twitter', url: "https://twitter.com/#{args.twitter_handle}").last
      if account.nil?
        puts "Could not find account from Twitter handle #{args.twitter_handle}! Please make sure that this account authenticated to Check before."
        exit
      end

      team = Team.where(slug: args.team_slug).last
      tb = BotUser.where(login: 'smooch').last
      tbi = TeamBotInstallation.where(user_id: tb&.id, team_id: team&.id).last
      if tbi.nil?
        puts "Could not find a Smooch bot installed in a team with slug #{args.team_slug}"
        exit
      end
      
      app_id = tbi.settings.with_indifferent_access[:smooch_app_id]
      Bot::Smooch.get_installation('smooch_app_id', app_id)
      api_client = Bot::Smooch.smooch_api_client
      api_instance = SmoochApi::IntegrationApi.new(api_client)
      params = {
        'type' => 'twitter',
        'tier' => args.twitter_tier,
        'envName' => args.twitter_env_name,
        'consumerKey' => CONFIG['twitter_consumer_key'],
        'consumerSecret' => CONFIG['twitter_consumer_secret'],
        'accessTokenKey' => account.omniauth_info['credentials']['token'],
        'accessTokenSecret' => account.omniauth_info['credentials']['secret'],
        'displayName' => 'Twitter'
      }
      body = SmoochApi::IntegrationCreate.new(params)
      
      begin
        result = api_instance.create_integration(app_id, body)
        puts result.inspect
      rescue SmoochApi::ApiError => e
        puts "Exception when calling the Smooch create integration API: #{e}"
      end
    end
  end
end
