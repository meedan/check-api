class ChangeTimestampsDefaultOnTiplineSubscription < ActiveRecord::Migration[5.2]
  def change
    change_column_default :tipline_subscriptions, :created_at, -> { 'CURRENT_TIMESTAMP' }
    change_column_default :tipline_subscriptions, :updated_at, -> { 'CURRENT_TIMESTAMP' }
  end
end
