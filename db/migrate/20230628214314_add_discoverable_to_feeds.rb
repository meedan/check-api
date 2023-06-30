class AddDiscoverableToFeeds < ActiveRecord::Migration[6.1]
  def change
    add_column :feeds, :discoverable, :boolean, default: false
  end
end
