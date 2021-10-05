class AddSourcesCountToProjectMedias < ActiveRecord::Migration[4.2]
  def change
    add_column :project_medias, :sources_count, :integer, null: false, default: 0
  end
end
