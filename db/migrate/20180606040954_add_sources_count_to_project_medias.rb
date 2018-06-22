class AddSourcesCountToProjectMedias < ActiveRecord::Migration
  def change
    add_column :project_medias, :sources_count, :integer, null: false, default: 0
  end
end
