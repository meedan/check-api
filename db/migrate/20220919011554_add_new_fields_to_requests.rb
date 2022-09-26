class AddNewFieldsToRequests < ActiveRecord::Migration[5.2]
  def change
    add_column :requests, :webhook_url, :string
    add_column :requests, :last_called_webhook_at, :datetime
    add_column :requests, :subscriptions_count, :integer, null: false, default: 0
  end
end
