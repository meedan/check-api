class AddArchivedFlag < ActiveRecord::Migration
  def change
    add_column :project_medias, :archived, :boolean, default: false
    add_index :project_medias, :archived

    add_column :sources, :archived, :boolean, default: false
    add_index :sources, :archived
    
    add_index :projects, :archived
    add_index :teams, :archived
  end
end
