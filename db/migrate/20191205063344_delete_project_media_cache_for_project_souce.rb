class DeleteProjectMediaCacheForProjectSouce < ActiveRecord::Migration[4.2]
  def change
  	Rails.cache.delete_matched('project_source_id_cache_for_project_media_*')
  end
end
