class AddApplicationToApiKeys < ActiveRecord::Migration
  def change
    add_column :api_keys, :application, :string
  end
end
