class AddFieldsToFeed < ActiveRecord::Migration[6.1]
  def change
    add_reference :feeds, :saved_search, index: true
    add_reference :feeds, :user, index: true
    add_column :feeds, :description, :text
    add_column :feeds, :tags, :jsonb, default: {}
    add_column :feeds, :licenses, :integer, array: true, default: []
    # Remove filters column
    remove_column :feeds, :filters
  end
end
