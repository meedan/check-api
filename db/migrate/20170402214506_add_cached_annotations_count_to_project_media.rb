class AddCachedAnnotationsCountToProjectMedia < ActiveRecord::Migration
  def change
    add_column :project_medias, :cached_annotations_count, :integer, default: 0
  end
end
