namespace :check do
  namespace :migrate do
    # bundle exec rake check:migrate:add_smooch_slack_url_annotation_field[team_slug:workspace_id]
    # first args should be redis_prefix
    task add_smooch_slack_url_annotation_field: :environment do |_t, args|
      # collect team_slug and workspace id for rake input
      team_slack = {}
      args.extras.each do |arg|
        t = arg.split(":")
        team_slack[t.first] = t.last
      end
      redis_prefix = team_slack['redis_prefix']
      redis = Redis.new
      redis.keys("slack_channel_smooch:#{redis_prefix}:*").each_slice(2000) do |bulk|
        smooch_users = {}
        redis.mget(bulk).each.with_index do |v, index|
          print "."
          # read values from redis and collect it in format smooch_user.id => slack channel url
          value = JSON.parse(v)
          _Klass, id = CheckGraphql.decode_id(value["annotation_id"])
          workspace_id = team_slack[value['team_slug']]
          channel_id = bulk[index].split(':').last
          slack_channel_url = "https://app.slack.com/client/#{workspace_id}/#{channel_id}"
          smooch_users[id.to_i] = slack_channel_url
        end
        Annotation.where(annotation_type: 'smooch_user', id: smooch_users.keys).find_in_batches(:batch_size => 2000) do |objs|
          print "."
          # get project teams
          project_team = {}
          Project.select(:id, :team_id).where(id: objs.map(&:annotated_id)).find_each do |pt|
            project_team[pt.id] = pt.team_id
          end
          fields = []
          dynamic_teams = {}
          dynamic_projects = {}
          objs.each do |obj|
            fields << DynamicAnnotation::Field.new({
              annotation_id: obj.id,
              annotation_type: obj.annotation_type,
              field_type: 'text',
              field_name:'smooch_user_slack_channel_url',
              value: smooch_users[obj.id],
              skip_notifications: true
            })
            dynamic_teams[obj.id] = project_team[obj.annotated_id]
            dynamic_projects[obj.id] = obj.annotated_id
          end
          if fields.size > 0
            DynamicAnnotation::Field.import(fields, recursive: false, validate: false)
            # cache slack check url values
            DynamicAnnotation::Field.where(field_name: 'smooch_user_data', annotation_id: dynamic_projects.keys)
            .find_in_batches(:batch_size => 2000) do |items|
              items.each do |f|
                # cache the value
                user_data = f.value_json
                cache_k = "SmoochUserSlackChannelUrl:Team:#{dynamic_teams[f.annotation_id]}:#{user_data['id']}"
                Rails.cache.write(cache_k, smooch_users[f.annotation_id])
              end
            end
          end
        end
      end
    end
  end
end
