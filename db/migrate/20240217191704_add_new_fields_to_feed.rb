class AddNewFieldsToFeed < ActiveRecord::Migration[6.1]
  def change
    add_column :feeds, :uuid, :string, null: false, default: ''
    add_column :feeds, :last_clusterized_at, :datetime
    add_index :feeds, :uuid
    Feed.find_each do |feed|
      feed.update_column :uuid, SecureRandom.uuid
    end
  end
end
