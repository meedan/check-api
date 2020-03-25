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
      redis.keys("slack_channel_smooch:*").each_slice(2500) do |bulk|
        fields = []
        dynamic_projects = {}
        dynamic_slack_url = {}
        redis.mget(bulk).each.with_index do |v, index|
          print "."
          value = JSON.parse(v)
          _Klass, id = CheckGraphql.decode_id(value["annotation_id"])
          a = Dynamic.where(id: id).last
          unless a.nil?
            workspace_id = team_slack[value['team_slug']]
            channel_id = bulk[index].split(':').last
            slack_channel_url = "https://app.slack.com/client/#{workspace_id}/#{channel_id}"
            fields << DynamicAnnotation::Field.new({
              annotation_id: a.id,
              annotation_type: a.annotation_type,
              field_type: 'text',
              field_name:'smooch_user_slack_channel_url',
              value: slack_channel_url,
              skip_notifications: true
            })
            dynamic_projects[a.id] = a.annotated_id
            dynamic_slack_url[a.id] = slack_channel_url
          end
        end
        if fields.size > 0
          DynamicAnnotation::Field.import(fields, recursive: false, validate: false)
          # cache slack check url values
          DynamicAnnotation::Field.where(field_name: 'smooch_user_data', annotation_id: dynamic_projects.keys)
          .find_in_batches(:batch_size => 2500) do |objs|
            cached_values = {}
            objs.each do |obj|
              # cache the value
              user_data = obj.value_json
              cache_k = "SmoochUserSlackChannelUrl:Project:#{dynamic_projects[obj.annotation_id]}:#{user_data['id']}"
              cached_values[cache_k] = dynamic_slack_url[obj.annotation_id]
            end
            begin
              redis.mapped_mset(cached_values) if cached_values.size > 0
            rescue Exception => e
              puts "Restarting redis ...."
              redis = Redis.new
              redis.mapped_mset(cached_values) if cached_values.size > 0
            end
          end
        end
      end
    end
  end
end
