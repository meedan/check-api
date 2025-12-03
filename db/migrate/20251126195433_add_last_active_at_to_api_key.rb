class AddLastActiveAtToApiKey < ActiveRecord::Migration[6.1]
  def change
    add_column :api_keys, :last_active_at, :datetime
  end
end
