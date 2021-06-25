class AddApiKeyIdToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :api_key_id, :integer
  end
end
