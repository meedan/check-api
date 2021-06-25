class AddApplicationToApiKeys < ActiveRecord::Migration[4.2]
  def change
    add_column :api_keys, :application, :string
  end
end
