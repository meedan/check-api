namespace :check do
  namespace :migrate do
    task add_smooch_slack_url_annotation_field: :environment do
      team_slack = {
        'meedan' => 'T02528QUL',
        'reverso' => 'TL42Y75KQ',
        'afp-checamos' => 'TPEH5QGFQ',
        'africa-check' => 'TNZKK0ZCJ',
        'india-today' => 'TPCDW80JC',
        'boom' => 'TPB3ESMSM',
        'AFP India' => 'TPPG60VU0', #TODO: get team slug
        'caiosba' => 'T9KSRBDNV',
        'test-noha-121' => 'T9S51P132',
        'pesacheck' => 'T029WTKK9',
        'zimbabwe-facts' => 'T4N7VL98C', #TODO: get team slug
        'Verafiles' => 'TA2K7Q0J3', #TODO: get team slug
        'AAJA Asia' => 'T03N47TET', #TODO: get team slug
        'Moldova' => 'TFX718469' #TODO: get team slug
      }
      # Connection info https://github.com/meedan/configurator/blob/master/check/live/check-slack-bot/config.js#L96-L98
      redis = Redis.new(host: '', port: '', db: '')
      # Sample of key and value
      # key = 'slack_channel_smooch:redisPrefix:eventChannel'
      # v = { team_slug: "teamSlug", annotation_id: "id", mode: 'bot' }.to_json
      redis.keys("slack_channel_smooch:*").each do |k|
        value = JSON.parse(redis.get(k))
        a = Dynamic.where(id: value['annotation_id']).last
        unless a.nil?
          workspace_id = team_slack[value['team_slug']]
          channel_id = k.split(':').last
          a.set_fields = { smooch_user_slack_channel_url: "https://app.slack.com/client/#{workspace_id}/#{channel_id}" }.to_json
          a.save!
        end
      end
    end
  end
end
