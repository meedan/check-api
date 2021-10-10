class AddPlatformToTiplineSubscription < ActiveRecord::Migration[5.2]
  def change
    add_column :tipline_subscriptions, :platform, :string
    add_index :tipline_subscriptions, :platform
    TiplineSubscription.update_all(platform: 'WhatsApp')
  end
end
