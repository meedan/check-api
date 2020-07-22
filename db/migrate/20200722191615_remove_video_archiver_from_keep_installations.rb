class RemoveVideoArchiverFromKeepInstallations < ActiveRecord::Migration
  def change
    bot = BotUser.find_by(login: 'keep')
    unless bot.nil?
      TeamBotInstallation.where(user_id: bot.id).each do |tb|
        settings = tb.settings.with_indifferent_access
        if settings.has_key?(:archive_video_archiver_enabled)
          settings.delete(:archive_video_archiver_enabled)
          tb.settings = settings
          tb.save!
        end
      end
    end
  end
end
