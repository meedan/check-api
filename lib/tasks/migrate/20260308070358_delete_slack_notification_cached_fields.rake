namespace :check do
  namespace :migrate do
    # bundle exec rails check:migrate:delete_slack_notification_cached_data
    task delete_slack_notification_cached_data: :environment do
      started = Time.now.to_i
      last_team_id = Rails.cache.read('check:migrate:delete_slack_notification_cached_data') || 0
      Team.where('id > ?', last_team_id).find_each do |team|
        puts "Processing team #{team.id}\n"
        Annotation.where(annotated_type: 'Team', annotated_id: team.id, annotation_type: 'smooch_user')
        .find_in_batches(batch_size: 2000) do |annotations|
          a_ids = annotations.pluck(:id)
          DynamicAnnotation::Field.where(annotation_id: a_ids, field_name: 'smooch_user_id').find_each do |f|
            print '.'
            cache_slack_key = "SmoochUserSlackChannelUrl:Team:#{team.id}:#{f.value}"
            Rails.cache.delete(cache_slack_key)
          end
          DynamicAnnotation::Field.where(annotation_id: a_ids, field_name: 'smooch_user_data').find_each do |f|
            print '.'
            data = f.value_json
            query = { field_name: 'smooch_user_data', json: { app_name: data['app_name'], identifier: data['identifier'] } }.to_json
            cache_key = 'dynamic-annotation-field-' + Digest::MD5.hexdigest(query)
            Rails.cache.delete(cache_key)
          end
        end
        Rails.cache.write('check:migrate:delete_slack_notification_cached_data', team.id)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end