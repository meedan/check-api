class AddPrivacyStatementSettingToSmoochBot < ActiveRecord::Migration[4.2]
  def change
    tb = BotUser.where(login: 'smooch').last
    unless tb.nil?
      settings = tb.get_settings.clone
      i = settings.find_index{ |s| s['name'] == 'smooch_workflows' }
      settings[i]['items']['properties']['smooch_message_smooch_bot_tos'] = {
        "type": "object",
        "title": "Privacy statement",
        "properties": {
          "greeting": {
            "type": "string",
            "default": ""
          },
          "content": {
            "type": "string",
            "default": ""
          }
        }
      }
      tb.set_settings(settings)
      tb.save!
    end
  end
end
