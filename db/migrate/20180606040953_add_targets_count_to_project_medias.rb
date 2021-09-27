class AddTargetsCountToProjectMedias < ActiveRecord::Migration[4.2]
  def change
    add_column :project_medias, :targets_count, :integer, null: false, default: 0
  end
end
