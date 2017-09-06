class AddCachedAnnotationsCountToProjectSource < ActiveRecord::Migration
  def change
    add_column :project_sources, :cached_annotations_count, :integer, default: 0
  end
end
