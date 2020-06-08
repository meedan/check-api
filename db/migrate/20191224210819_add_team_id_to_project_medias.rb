class AddTeamIdToProjectMedias < ActiveRecord::Migration
  def change
    add_column :project_medias, :team_id, :integer
    add_index :project_medias, :team_id
  end
end
