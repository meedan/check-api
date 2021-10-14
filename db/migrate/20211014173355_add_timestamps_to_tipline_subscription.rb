class AddTimestampsToTiplineSubscription < ActiveRecord::Migration[5.2]
  def change
    add_timestamps :tipline_subscriptions, default: DateTime.now
  end
end
