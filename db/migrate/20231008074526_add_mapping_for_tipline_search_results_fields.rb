class AddMappingForTiplineSearchResultsFields < ActiveRecord::Migration[6.1]
  def change
    options = {
      index: CheckElasticSearchModel.get_index_alias,
      body: {
        properties: {
          positive_tipline_search_results_count: { type: 'long' },
          tipline_search_results_count: { type: 'long' },
        }
      }
    }
    $repository.client.indices.put_mapping options
  end
end
