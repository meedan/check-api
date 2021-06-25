class AddArchivedFlag < ActiveRecord::Migration[4.2]
  def change
    add_column :project_medias, :archived, :integer, default: 0
    add_index :project_medias, :archived

    add_column :sources, :archived, :integer, default: 0
    add_index :sources, :archived
    
    add_index :projects, :archived
    add_index :teams, :archived
  end
end
