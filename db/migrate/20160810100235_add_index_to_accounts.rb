class AddIndexToAccounts < ActiveRecord::Migration
  def change
    #add_column :accounts, :url, :string
    add_index :accounts, :url, unique: true
  end
end
