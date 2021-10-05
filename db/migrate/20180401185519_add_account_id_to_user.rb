class AddAccountIdToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :account_id, :integer
    add_index :users, :account_id
    User.find_each do |u|
      a = u.source.accounts.first
      u.update_columns(account_id: a.id) unless a.nil?
    end
  end
end
