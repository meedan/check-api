class AllowEmptyProjectMediaIdForClusters < ActiveRecord::Migration[6.1]
  def change
    change_column_null(:clusters, :project_media_id, true)
  end
end
