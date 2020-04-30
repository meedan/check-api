class RemoveAssignmentsProgressCacheAndEsDeadlineField < ActiveRecord::Migration
  def change
  	# calling reindex to remove `deadline` field
    CheckElasticSearchModel.reindex_es_data
  	Rails.cache.delete_matched('cache-assignments-progress-*')
  end
end
