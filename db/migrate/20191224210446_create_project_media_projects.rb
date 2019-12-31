class CreateProjectMediaProjects < ActiveRecord::Migration
  def change
    create_table :project_media_projects do |t|
      t.references :project_media
      t.references :project
    end
    add_index :project_media_projects, :project_media_id
    add_index :project_media_projects, :project_id
    add_index :project_media_projects, [:project_media_id, :project_id], unique: true
  end
end
