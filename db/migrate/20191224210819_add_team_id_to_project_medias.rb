class AddTeamIdToProjectMedias < ActiveRecord::Migration[4.2]
  def change
    add_column :project_medias, :team_id, :integer
    add_index :project_medias, :team_id
  end
end
