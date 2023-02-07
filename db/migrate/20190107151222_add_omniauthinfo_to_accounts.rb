class AddOmniauthinfoToAccounts < ActiveRecord::Migration[4.2]
  def change
  	remove_columns :users, :provider, :uuid, :omniauth_info, :account_id
    add_index :users, :email
  end
end
