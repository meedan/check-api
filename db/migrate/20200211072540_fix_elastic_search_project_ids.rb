class FixElasticSearchProjectIds < ActiveRecord::Migration
  def change
  	# Store latest project media id
    Rails.cache.write('check:migrate:fix_elastic_search_project_ids:last_id', ProjectMedia.last&.id || 0)
  end
end
