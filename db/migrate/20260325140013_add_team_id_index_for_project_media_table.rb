class AddTeamIdIndexForProjectMediaTable < ActiveRecord::Migration[6.1]
  def change
    add_index :project_medias, :team_id
  end
end
