class AddIndexToUserSourceId < ActiveRecord::Migration
  def change
    add_index :users, :source_id
  end
end
