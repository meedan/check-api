class AddCurrentTeamIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :current_team_id, :int
  end
end
