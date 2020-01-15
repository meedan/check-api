class AddSortableFieldsToElasticSeearch < ActiveRecord::Migration
  def change
  	index_name = CheckElasticSearchModel.get_index_name
    client = MediaSearch.gateway.client
    options = {
    	index: index_name,
      type: 'media_search',
      body: {
	    	media_search: {
	    		properties: {
	    			requests_count: { type: 'integer' },
	    			linked_items_count: { type: 'integer' },
	    			last_seen: { type: 'integer' }
	    		}
	    	}
	    }
    }
    client.indices.put_mapping options
    ProjectMedia.find_each do |pm|
    	doc_id = Base64.encode64("#{pm.class.name}/#{pm.id}")
    	fields = { 'requests_count' => pm.requests_count.to_i, 'linked_items_count' => pm.linked_items_count.to_i, 'last_seen' => pm.last_seen.to_i }
    	client.update index: index_name, type: 'media_search', id: doc_id, body: { doc: fields }
    end
  end
end
