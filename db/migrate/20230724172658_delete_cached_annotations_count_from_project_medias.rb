class DeleteCachedAnnotationsCountFromProjectMedias < ActiveRecord::Migration[6.1]
  def change
    remove_column :project_medias, :cached_annotations_count, if_exists: true
  end
end
