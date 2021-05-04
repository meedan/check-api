class AddIndexesToProjectMedias < ActiveRecord::Migration
  def change
  	remove_index :project_medias, name: "index_project_medias_on_project_id"
  	remove_index :project_medias, name: "index_project_medias_on_team_id"
  	add_index :project_medias, [:team_id, :archived, :sources_count]
  	add_index :project_medias, :project_id
  end
end
