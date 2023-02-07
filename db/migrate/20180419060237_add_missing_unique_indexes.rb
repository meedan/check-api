class AddMissingUniqueIndexes < ActiveRecord::Migration[4.2]
  def change
    # add unique indexes
  	add_index :account_sources, [:account_id, :source_id], unique: true
  end
end
