class AddTitleDescToApiKeys < ActiveRecord::Migration[6.1]
  def change
    add_column(:api_keys, :title, :string) unless column_exists?(:api_keys, :title)
    add_column :api_keys, :description, :string
    add_reference(:api_keys, :team, foreign_key: true, null: true) unless column_exists?(:api_keys, :team_id)
    add_reference(:api_keys, :user, foreign_key: true, null: true) unless column_exists?(:api_keys, :user_id)
  end
end
