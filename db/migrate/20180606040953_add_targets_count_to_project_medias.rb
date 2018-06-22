class AddTargetsCountToProjectMedias < ActiveRecord::Migration
  def change
    add_column :project_medias, :targets_count, :integer, null: false, default: 0
  end
end
