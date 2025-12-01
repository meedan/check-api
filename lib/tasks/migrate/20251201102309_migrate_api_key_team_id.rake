namespace :check do
  namespace :migrate do
    # bundle exec rails check:migrate:migrate_api_key_team_id
    task migrate_api_key_team_id: :environment do
      started = Time.now.to_i
      ApiKey.where('team_id is NULL').find_each do |api_key|
        print '.'
        unless api_key.bot_user.nil?
          team_id = api_key.bot_user.team&.id
          unless team_id.nil?
            api_key.update_column(:team_id, team_id)
            data << {id: api_key.id, team_id: team_id}
          end
        end
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
    # bundle exec rails check:migrate:list_global_api_keys
    task list_global_api_keys: :environment do
      started = Time.now.to_i
      global_keys = []
      ApiKey.find_each do |api_key|
        print '.'
        global_keys << {id: api_key.id, access_token: api_key.access_token} if api_key.bot_user.nil?
      end
      puts "\nGloabl Keys\n"
      pp global_keys
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end