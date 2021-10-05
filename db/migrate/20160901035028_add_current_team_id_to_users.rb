class AddCurrentTeamIdToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :current_team_id, :int
  end
end
