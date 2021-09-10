class AddTimeToSendRequestSettingToSmoochBot < ActiveRecord::Migration
  def change
    tb = BotUser.smooch_user
    unless tb.nil?
      new_setting = {
        name: 'smooch_time_to_send_request',
        label: 'Time to send request. Choose the amount of seconds users have to submit a request. The counter resets every time a user submits a message.',
        type: 'number',
        default: 30
      }
      settings = tb.get_settings.clone || []
      i = settings.find_index{ |s| s['name'] == 'smooch_disabled' }
      if i
        settings.insert(i, new_setting)
      else
        settings << new_setting
      end
      tb.set_settings(settings)
      tb.save!
    end
  end
end
