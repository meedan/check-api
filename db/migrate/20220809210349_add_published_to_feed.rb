class AddPublishedToFeed < ActiveRecord::Migration[5.2]
  def change
    add_column :feeds, :published, :boolean, default: false
  end
end
