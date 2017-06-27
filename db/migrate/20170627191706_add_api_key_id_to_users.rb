class AddApiKeyIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :api_key_id, :integer
  end
end
