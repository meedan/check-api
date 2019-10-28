class AddTypeIndexToUsers < ActiveRecord::Migration
  def change
    add_index :users, :type
  end
end
