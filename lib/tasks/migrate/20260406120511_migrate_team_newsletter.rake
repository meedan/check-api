namespace :check do
  namespace :migrate do
    # bundle exec rails check:migrate:migrate_tipline_newsletter_action
    desc 'Enable/disable tipline newsletter based on tipline platform'
    task migrate_tipline_newsletter_action: :environment do
      started = Time.now.to_i
      smooch = BotUser.smooch_user
      output = []
      TeamBotInstallation.where(user_id: smooch.id).find_each do |tbi|
        print '.'
        integrations = tbi.smooch_enabled_integrations
        unless integrations.empty?
          team = tbi.team
          action = 2
          if integrations.count == 1 
            action = !(integrations.keys == ['whatsapp'])
          elsif !integrations.keys.include?('whatsapp')
            action = 1
          else
            platforms = TiplineSubscription.where(team_id: team.id).map(&:platform).uniq
            if platforms.count == 1
              action = !(platforms == ['WhatsApp'])
            end
          end
          output << { team: team.slug, action: action.to_i }
          team.set_tipline_newsletter_enabled = action.to_i
          team.save!
        end
      end
      puts "Workspace actions......\n"
      pp output
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
    # bundle exec rails "check:migrate:set_tipline_newsletter_subscribers_limit[slug, limit]"
    desc 'Set tipline newsletter subscribers limit, 0 means no limit'
    task :set_tipline_newsletter_subscribers_limit, [:slug, :limit] => :environment do |_t, args|
      raise "You should set team slug" if args[:slug].blank?
      team = Team.where(slug: args[:slug]).first
      unless team.nil?
        limit = args[:limit].to_i == 0 ? nil : args[:limit].to_i
        team.set_tipline_newsletter_subscribers_limit = limit
        team.save!
      end
    end
    # bundle exec rails "check:migrate:set_tipline_newsletter_action[slug, true/false]"
    desc 'Enable/Disable tipline newsletter'
    task :set_tipline_newsletter_action, [:slug, :action] => :environment do |_t, args|
      raise "You should set team slug" if args[:slug].blank?
      team = Team.where(slug: args[:slug]).first
      unless team.nil?
        team.set_tipline_newsletter_enabled = ActiveModel::Type::Boolean.new.cast(args[:action])
        team.save!
      end
    end
  end
end
