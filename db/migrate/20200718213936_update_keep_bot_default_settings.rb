class UpdateKeepBotDefaultSettings < ActiveRecord::Migration
  def change
    bot = BotUser.find_by(login: 'keep')
    settings = bot.get_settings

    settings.delete_if { |s| s['name'] == 'archive_video_archiver_enabled' }
    settings.map { |s| s['default'] = false }

    bot.set_settings(settings)
    bot.save!
  end
end
