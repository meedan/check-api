class AddTiplineBotV2SettingsToSmoochBot < ActiveRecord::Migration[5.2]
  def change
    tb = BotUser.smooch_user
    unless tb.nil?
      settings = tb.get_settings.clone || []
      settings << {
        name: 'smooch_search_text_similarity_threshold',
        label: 'Similarity threshold to be used when searching for similar texts',
        type: 'string',
        default: '0.9'
      }
      settings << {
        name: 'smooch_search_max_keyword',
        label: 'Maximum number of words to perform a keyword search instead of a similarity search',
        type: 'number',
        default: 3
      }
      tb.set_settings(settings)
      tb.save!
    end
  end
end
