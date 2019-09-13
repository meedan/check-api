class AddTwitterSettingsToSmoochBot < ActiveRecord::Migration
  def change
    Dynamic.where(annotation_type: 'smooch_user').destroy_all
    tb = BotUser.where(login: 'smooch').last
    unless tb.nil?
      settings = tb.get_settings.clone || []
      settings.insert(-2, { name: 'smooch_twitter_authorization_url', label: 'Visit this link to authorize the Twitter Business Account that will forward DMs to this bot', type: 'readonly', default: '' })
      settings << { name: 'smooch_authorization_token', label: 'Internal Token (used for authorization)', type: 'hidden', default: '' }
      tb.set_settings(settings)
      tb.save!

      TeamBotInstallation.where(user_id: tb.id).each do |tbi|
        token = SecureRandom.hex
        tbi.set_smooch_authorization_token = token
        tbi.set_smooch_twitter_authorization_url = "#{CONFIG['checkdesk_base_url']}/api/users/auth/twitter?context=smooch&destination=#{CONFIG['checkdesk_base_url']}/api/admin/smooch_bot/#{tbi.id}/authorize/twitter?token=#{token}"
        tbi.save!
      end
    end
  end
end
