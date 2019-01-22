class AddOmniauthinfoToAccounts < ActiveRecord::Migration
  def change
  	add_column :accounts, :omniauth_info, :text
  	add_column :accounts, :uid, :string
  	add_column :accounts, :provider, :string
  	add_column :accounts, :token, :string
  	# Migrate existin social media login into account
  	User.where('provider IS NOT NULL').find_each do |u|
      a = Account.where(id: u.account_id).last
  		unless a.nil?
  			updates = {uid: u.uuid, omniauth_info: u.omniauth_info, provider: u.provider, token: u.token}
  			a.update_columns(updates)
  		end
  	end
  	remove_columns :users, :provider, :uuid, :omniauth_info, :account_id
    add_index :accounts, [:uid, :provider, :token]
  end
end
