class AddNoActionSettingToSmoochBot < ActiveRecord::Migration[4.2]
  def change
    tb = BotUser.where(login: 'smooch').last
    unless tb.nil?
      settings = tb.get_settings.clone
      i = settings.find_index{ |s| s['name'] == 'smooch_workflows' }
      settings[i]['items']['properties']['smooch_message_smooch_bot_no_action'] = {
        "type": "object",
        "title": "No action resource",
        "properties": {
          "smooch_custom_resource_body" => {
            "type" => "string",
            "title" => "Body",
            "default" => ""
          },
          "smooch_custom_resource_feed_url" => {
            "type" => "string",
            "title" => "Feed URL",
            "default" => ""
          },
          "smooch_custom_resource_number_of_articles" => {
            "type" => "integer",
            "title" => "Number of articles",
            "default" => 3
          }
        }
      }
      tb.set_settings(settings)
      tb.save!
    end
  end
end
