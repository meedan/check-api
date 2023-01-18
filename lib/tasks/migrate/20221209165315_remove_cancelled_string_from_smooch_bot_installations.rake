namespace :check do
  namespace :migrate do
    task remove_cancelled_string_from_smooch_bot_installations: :environment do
      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil

      started = Time.now.to_i
      RequestStore.store[:skip_notifications] = true
      RequestStore.store[:skip_clear_cache] = true
      RequestStore.store[:skip_rules] = true

      bot = BotUser.find_by(login: 'smooch')
      unless bot.nil?
        n = 0
        TeamBotInstallation.where(user_id: bot.id).each do |tbi|
          tbi.get_smooch_workflows.each { |w| w.to_h.delete('cancelled') }
          tbi.save!
          n += 1
        end
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Removed string from #{n} Smooch Bot installations in #{minutes} minutes."

      RequestStore.store[:skip_notifications] = false
      RequestStore.store[:skip_clear_cache] = false
      RequestStore.store[:skip_rules] = false
      ActiveRecord::Base.logger = old_logger
    end
  end
end
