class UpdateSmoochBotSettings < ActiveRecord::Migration[4.2]
  def change
    bot = BotUser.smooch_user
    unless bot.nil? 
      TeamBotInstallation.where(user_id: bot.id).each do |tbi|
        settings = tbi.settings || {}
        bot.get_settings.each do |setting|
          s = setting.with_indifferent_access
          type = s[:type]
          default = s[:default]
          default = default.to_i if type == 'number'
          default = (default == 'true') if type == 'boolean'
          default ||= [] if type == 'array'
          settings[s[:name]] = default unless settings.has_key?(s[:name])
        end
        tbi.settings = settings
        tbi.save!
      end
    end
  end
end
