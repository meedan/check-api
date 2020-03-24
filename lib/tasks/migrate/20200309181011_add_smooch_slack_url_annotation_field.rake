namespace :check do
  namespace :migrate do
    # bundle exec rake check:migrate:add_smooch_slack_url_annotation_field[team_slug:workspace_id]
    task add_smooch_slack_url_annotation_field: :environment do |_t, args|
      team_slack = {}
      args.extras.each do |arg|
        t = arg.split(":")
        team_slack[t.first] = t.last
      end
      redis = Redis.new
      redis.keys("slack_channel_smooch:*").each do |k|
        print "."
        value = JSON.parse(redis.get(k))
        Klass, id = CheckGraphql.decode_id(value["annotation_id"])
        a = Dynamic.where(id: id).last
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
