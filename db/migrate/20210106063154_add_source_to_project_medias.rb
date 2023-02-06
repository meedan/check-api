class AddSourceToProjectMedias < ActiveRecord::Migration[4.2]
  def change
    # remove_column :accounts, :team_id
    add_column :project_medias, :source_id, :integer
    add_index :project_medias, :source_id
  end
end
