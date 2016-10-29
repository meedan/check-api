class AddOmniauthinfoToUsers < ActiveRecord::Migration
  def change
    add_column :users, :omniauth_info, :text
  end
end
