class AddMissingIndex < ActiveRecord::Migration
  def change
    add_index :team_users, [:user_id, :team_id]
  end
end
