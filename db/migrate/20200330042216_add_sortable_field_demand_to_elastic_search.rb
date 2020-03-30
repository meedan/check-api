class AddSortableFieldDemandToElasticSearch < ActiveRecord::Migration
  def change
    index_alias = CheckElasticSearchModel.get_index_alias
    client = MediaSearch.gateway.client
    options = {
      index: index_alias,
      type: 'media_search',
      body: {
        media_search: {
          properties: {
            demand: { type: 'long' }
          }
        }
      }
    }
    client.indices.put_mapping options
    # Store latest project media id
    Rails.cache.write('check:migrate:add_sortable_field_demand_to_elastic_search:last_id', ProjectMedia.last&.id || 0)
  end
end
