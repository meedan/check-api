class AddOmniauthinfoToAccounts < ActiveRecord::Migration
  def change
  	add_column :accounts, :omniauth_info, :text
  	add_column :accounts, :uid, :string
  	add_column :accounts, :provider, :string
  	add_column :accounts, :token, :string
  	# Migrate existin social media login into account
  	User.where('provider IS NOT NULL').find_each do |u|
  		a = u.account
  		unless a.nil?
  			updates = {uid: u.uuid, omniauth_info: u.omniauth_info, provider: u.provider, token: u.token}
  			a.update_columns(updates)
  			u.update_columns(token: nil)
  		end
  	end
  	remove_columns :users, :provider, :uuid, :omniauth_info
  end
end
