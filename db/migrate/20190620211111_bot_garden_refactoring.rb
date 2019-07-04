class BotGardenRefactoring < ActiveRecord::Migration
  def change
    RequestStore.store[:skip_notifications] = true
    config = CONFIG['clamav_service_path']
    CONFIG['clamav_service_path'] = nil

    puts "[#{Time.now}] Refactoring Bot Garden"
    
    puts "[#{Time.now}] Adding settings column to team_users table..."
    unless column_exists? :team_users, :settings
      add_column :team_users, :settings, :text
    end
    unless column_exists? :team_users, :type
      add_column :team_users, :type, :string
      add_index :team_users, :type
    end
    TeamUser.reset_column_information

    puts "[#{Time.now}] Converting team_bots and removing the table..."
    mapping = {}
    if ActiveRecord::Base.connection.table_exists?(:team_bots)
      ActiveRecord::Base.connection.execute('SELECT * FROM team_bots').to_a.each do |team_bot|
        bot_user = BotUser.find(team_bot['bot_user_id'])
        mapping[team_bot['id']] = team_bot['bot_user_id']
        s = team_bot.clone.with_indifferent_access
        settings = {}.with_indifferent_access
        settings['events'] = s['events'].blank? ? [] : YAML::load(s['events'])
        settings['settings'] = s['settings'].blank? ? [] : YAML::load(s['settings'])
        settings['approved'] = s['approved'].to_s == 't'
        settings['limited'] = s['limited'].to_s == 't'
        ['description', 'request_url', 'role', 'version', 'source_code_url', 'team_author_id', 'last_called_at'].each do |key|
          settings[key] = s[key]
        end
        bot_user.settings = settings
        bot_user.save!
      end
      drop_table :team_bots
    end

    puts "[#{Time.now}] Converting team_bot_installations and removing the table..."
    if ActiveRecord::Base.connection.table_exists?(:team_bot_installations)
      ActiveRecord::Base.connection.execute('SELECT * FROM team_bot_installations').to_a.each do |tbi|
        tu = TeamUser.where(team_id: tbi['team_id'], user_id: mapping[tbi['team_bot_id']]).last
        tu.type = 'TeamBotInstallation'
        tu.settings = tbi['settings'].blank? ? {} : YAML::load(tbi['settings'])
        tu.save!
      end
      drop_table :team_bot_installations
    end
   
    puts "[#{Time.now}] Converting Bot::* classes..."
    if ActiveRecord::Base.connection.table_exists?(:bot_bots)
      old_pender = nil
      old_check = nil
      ActiveRecord::Base.connection.execute('SELECT * FROM bot_bots').to_a.each do |b|
        old_pender = b['id'] if b['name'] == 'Pender'
        old_check = b['id'] if b['name'] == 'Check Bot'
      end
      pender = BotUser.where(login: 'pender').last || BotUser.create!(name: 'Pender', login: 'pender')
      check = BotUser.where(login: 'check_bot').last || BotUser.create!(name: 'Check Bot', login: 'check_bot')
      Annotation.where(annotator_type: 'Bot::Bot', annotator_id: old_pender).update_all(annotator_type: 'BotUser', annotator_id: pender.id)
      Annotation.where(annotator_type: 'Bot::Bot', annotator_id: old_check).update_all(annotator_type: 'BotUser', annotator_id: check.id)
    end

    ['alegre', 'facebook', 'twitter', 'slack', 'bridge_reader', 'viber'].each do |identifier|
      if ActiveRecord::Base.connection.table_exists?("bot_#{identifier.pluralize}")
        old = nil
        name = identifier.camelize.gsub(/([a-z])([A-Z])/, '\1 \2') + ' Bot'
        klass = 'Bot::' + identifier.camelize
        new = BotUser.where(login: identifier).last || User.create!(name: name, login: identifier, type: klass)
        new = BotUser.find(new.id)
        ActiveRecord::Base.connection.execute("SELECT * FROM bot_#{identifier.pluralize}").to_a.each do |b|
          if b['name'] == name
            old = b['id']
            unless b['settings'].blank?
              settings = YAML::load(b['settings'])
              if settings.is_a?(Hash)
                new.settings = settings
                new.save!
              end
            end
          end
        end
        Annotation.where(annotator_type: "Bot::#{identifier.camelize}", annotator_id: old.to_i).update_all(annotator_type: klass, annotator_id: new.id)
      end
    end

    puts "[#{Time.now}] Removing other bot-specific tables..."
    ['bot_alegres', 'bot_bots', 'bot_bridge_readers', 'bot_facebooks', 'bot_slacks', 'bot_twitters', 'bot_vibers'].each do |table|
      drop_table(table) if ActiveRecord::Base.connection.table_exists?(table)
    end

    CONFIG['clamav_service_path'] = config
    RequestStore.store[:skip_notifications] = false
  end
end
