class AddTitleDescToApiKeys < ActiveRecord::Migration[6.1]
  def change
    add_column :api_keys, :title, :string
    add_column :api_keys, :description, :string
    add_column(:api_keys, :team_id, :integer) unless column_exists?(:api_keys, :team_id)
    add_column(:api_keys, :user_id, :integer) unless column_exists?(:api_keys, :user_id)
  end
end
