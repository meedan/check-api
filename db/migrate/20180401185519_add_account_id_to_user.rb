class AddAccountIdToUser < ActiveRecord::Migration
  def change
    add_reference :users, :account, index: true, foreign_key: true
    User.find_each do |u|
      a = u.source.accounts.first
      u.update_columns(account_id: a.id) unless a.nil?
    end
  end
end
