class AddCachedAnnotationsCountToProjectMedia < ActiveRecord::Migration[4.2]
  def change
    add_column :project_medias, :cached_annotations_count, :integer, default: 0
  end
end
