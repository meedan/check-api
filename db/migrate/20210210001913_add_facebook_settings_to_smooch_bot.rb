class AddFacebookSettingsToSmoochBot < ActiveRecord::Migration[4.2]
  def change
    tb = BotUser.smooch_user
    unless tb.nil?
      settings = tb.get_settings.clone || []
      settings.insert(-2, { name: 'smooch_facebook_authorization_url', label: 'Visit this link to connect a Facebook integration', type: 'readonly', default: '' })
      tb.set_settings(settings)
      tb.save!

      TeamBotInstallation.where(user_id: tb.id).each do |tbi|
        token = tbi.get_smooch_authorization_token
        if token.blank?
          token = SecureRandom.hex
          tbi.set_smooch_authorization_token = token
        end
        tbi.set_smooch_facebook_authorization_url = "#{CheckConfig.get('checkdesk_base_url')}/api/users/auth/facebook?context=smooch&destination=#{CheckConfig.get('checkdesk_base_url')}/api/admin/smooch_bot/#{tbi.id}/authorize/facebook?token=#{token}"
        tbi.save!
      end
    end
  end
end
