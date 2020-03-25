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
      errors = []
      redis.keys("slack_channel_smooch:*").each_slice(1250) do |bulk|
        redis.mget(bulk).each.with_index do |v, index|
          print "."
          value = JSON.parse(v)
          _Klass, id = CheckGraphql.decode_id(value["annotation_id"])
          a = Dynamic.where(id: id).last
          unless a.nil?
            workspace_id = team_slack[value['team_slug']]
            channel_id = bulk[index].split(':').last
            f = DynamicAnnotation::Field.new
            f.annotation_id = a.id
            f.annotation_type = a.annotation_type
            f.field_type = 'text'
            f.field_name = 'smooch_user_slack_channel_url'
            f.value = "https://app.slack.com/client/#{workspace_id}/#{channel_id}"
            f.skip_notifications = true
            begin
              f.save!
            rescue
              errors << {id: a.id, key: bulk[index]}
            end
          end
        end
      end
      unless errors.blank?
        puts "Failed to save #{errors.size} annotations."
        pp errors
      end
    end
  end
end
