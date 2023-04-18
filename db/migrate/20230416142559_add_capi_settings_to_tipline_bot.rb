class AddCapiSettingsToTiplineBot < ActiveRecord::Migration[5.2]
  def change
    tb = BotUser.where(login: 'smooch').last
    unless tb.nil?
      settings = tb.get_settings.clone
      {
        'capi_whatsapp_business_account_id' => 'WhatsApp Business Account ID',
        'capi_verify_token' => 'Webhook verify token',
        'capi_permanent_token' => 'Permanent token',
        'capi_phone_number_id' => 'Phone number ID',
        'capi_phone_number' => 'Phone number (only numbers)'
      }.each do |name, label|
        settings << {
          name: name,
          label: label,
          type: 'string',
          default: ''
        }
      end
      tb.set_settings(settings)
      tb.save!
    end
  end
end
