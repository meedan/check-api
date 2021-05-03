class AddUserIdIndexToAccounts < ActiveRecord::Migration
  def change
  	add_index :accounts, :user_id
  end
end
