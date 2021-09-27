class AddTypeIndexToUsers < ActiveRecord::Migration[4.2]
  def change
    add_index :users, :type
  end
end
