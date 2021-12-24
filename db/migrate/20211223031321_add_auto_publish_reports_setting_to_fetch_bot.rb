class AddAutoPublishReportsSettingToFetchBot < ActiveRecord::Migration[5.2]
  def change
    tb = BotUser.fetch_user
    unless tb.nil?
      new_setting = {
        name: 'auto_publish_reports',
        label: 'Auto-publish reports',
        type: 'boolean',
        default: false
      }
      settings = tb.get_settings.clone || []
      settings << new_setting
      tb.set_settings(settings)
      tb.save!
    end
  end
end
