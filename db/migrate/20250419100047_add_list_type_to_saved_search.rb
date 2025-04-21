class AddListTypeToSavedSearch < ActiveRecord::Migration[6.1]
  def change
    add_column :saved_searches, :list_type, :integer, null: false, default: 0
    add_index :saved_searches, :list_type
  end
end
