class AddIndexes < ActiveRecord::Migration[4.2]
  def change
    add_index :users, :id
  end
end
