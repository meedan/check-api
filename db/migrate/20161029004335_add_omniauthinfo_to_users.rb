class AddOmniauthinfoToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :omniauth_info, :text
  end
end
