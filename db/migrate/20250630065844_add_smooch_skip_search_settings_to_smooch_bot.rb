class AddSmoochSkipSearchSettingsToSmoochBot < ActiveRecord::Migration[6.1]
  def change
    tb = BotUser.smooch_user
    unless tb.nil?
      settings = tb.get_settings.clone || []
      settings << {
        name: 'smooch_skip_search',
        label: 'Should skip search (not use Alegre or the internal Check API search)',
        type: 'boolean',
        default: false
      }
      tb.set_settings(settings)
      tb.save!
    end
  end
end
