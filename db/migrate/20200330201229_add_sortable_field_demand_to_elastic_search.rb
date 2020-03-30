class AddSortableFieldDemandToElasticSearch < ActiveRecord::Migration
  def change
    # calling reindex will add `demand` and remove `requests_count` field
    CheckElasticSearchModel.reindex_es_data
    # Store latest project media id
    Rails.cache.write('check:migrate:add_sortable_field_demand_to_elastic_search:last_id', ProjectMedia.last&.id || 0)
  end
end
