class AddTripleIndexToTeamUser < ActiveRecord::Migration
  def change
    add_index :team_users, [:user_id, :team_id, :status]
  end
end
