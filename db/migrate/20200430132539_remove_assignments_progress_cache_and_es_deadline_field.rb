class RemoveAssignmentsProgressCacheAndEsDeadlineField < ActiveRecord::Migration
  def change
    # remove deadline field
    DynamicAnnotation::Field.where(field_name: 'deadline').delete_all
    DynamicAnnotation::FieldInstance.where(name: 'deadline').delete_all
    Rails.cache.delete_matched('cache-assignments-progress-*')
    # calling reindex to remove `deadline` field
    CheckElasticSearchModel.reindex_es_data
  end
end
