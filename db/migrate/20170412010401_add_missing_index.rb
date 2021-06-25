class AddMissingIndex < ActiveRecord::Migration[4.2]
  def change
    add_index :team_users, [:user_id, :team_id]
  end
end
