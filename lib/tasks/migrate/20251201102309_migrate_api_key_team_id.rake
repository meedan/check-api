namespace :check do
  namespace :migrate do
    # bundle exec rails check:migrate:migrate_api_key_team_id
    task migrate_api_key_team_id: :environment do
      started = Time.now.to_i
      # Update team_id based on bot_user.team value
      ApiKey.where('team_id is NULL').find_each do |api_key|
        print '.'
        unless api_key.bot_user.nil?
          team_id = api_key.bot_user.team&.id
          unless team_id.nil?
            api_key.update_column(:team_id, team_id)
          end
        end
      end
      # Check if bot user is a member of team
      ApiKey.where('team_id is NULL').find_each do |api_key|
        print '.'
        bu = api_key.bot_user
        unless bu.nil?
          if bu.team_users.count == 1
            tu = bu.team_users.first
            api_key.update_column(:team_id, tu.team_id)
          end
        end
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
    # bundle exec rails check:migrate:list_global_api_keys
    task list_global_api_keys: :environment do
      started = Time.now.to_i
      gk_without_bot = []
      gk_with_bot = []
      gk_with_bot_and_team = []
      ApiKey.where('team_id is NULL').find_each do |api_key|
        print '.'
        data = {
          id: api_key.id,
          access_token: api_key.access_token,
          expire_at: api_key.expire_at,
        }
        bu = api_key.bot_user
        if bu.nil?
          gk_without_bot << data
        else
          data['bot_user'] = { id: bu.id, name: bu.name }
          data['teams_count'] = bu.team_users.count
          if bu.team_users.count == 0
            gk_with_bot << data
          else
            data['teams'] = bu.teams.map(&:name).join("\n")
            gk_with_bot_and_team << data
          end
        end
      end
      puts "\nGloabl Keys\n"
      pp gk_without_bot
      puts "\nKeys with bot\n"
      pp gk_with_bot
      puts "\nKeys with bot and teams\n"
      pp gk_with_bot_and_team
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end