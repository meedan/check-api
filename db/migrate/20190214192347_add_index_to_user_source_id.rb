class AddIndexToUserSourceId < ActiveRecord::Migration[4.2]
  def change
    add_index :users, :source_id
  end
end
