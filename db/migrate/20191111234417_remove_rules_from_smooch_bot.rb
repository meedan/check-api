class RemoveRulesFromSmoochBot < ActiveRecord::Migration
  def change
    tb = BotUser.smooch_user
    unless tb.nil?
      settings = tb.get_settings.clone.select { |setting| setting.with_indifferent_access[:name] != 'smooch_rules_and_actions' }
      tb.set_settings(settings)
      tb.save!
    end
  end
end
