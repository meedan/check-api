class AddCreatedAtIndexForDataPoints < ActiveRecord::Migration[6.1]
  def change
    add_index :tipline_subscriptions, :created_at
    add_index :tipline_newsletter_deliveries, :created_at
    add_index :annotations, :created_at
  end
end
