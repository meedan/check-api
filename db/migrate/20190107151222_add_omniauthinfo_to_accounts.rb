class AddOmniauthinfoToAccounts < ActiveRecord::Migration
  def change
  	add_column :accounts, :omniauth_info, :text
  	add_column :accounts, :uid, :string
  	add_column :accounts, :provider, :string
  	add_column :accounts, :token, :string
    # Migrate provider value
    Account.find_each do |a|
      provider = a.data['provider']
      a.update_columns(provider: provider) unless provider.blank?
    end
  	# Migrate existin social media login into account
  	User.where.not(provider: "").find_each do |u|
      a = Account.where(id: u.account_id).last
  		unless a.nil?
        info = u.omniauth_info.nil? ? nil : YAML.load(u.omniauth_info)
  			updates = {uid: u.uuid, omniauth_info: info, provider: u.provider, token: u.token}
  			a.update_columns(updates)
        u.update_columns(encrypted_password: nil)
  		end
  	end
  	remove_columns :users, :provider, :uuid, :omniauth_info, :account_id
    add_index :accounts, [:uid, :provider, :token]
  end
end
