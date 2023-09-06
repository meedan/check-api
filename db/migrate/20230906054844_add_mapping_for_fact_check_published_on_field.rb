class AddMappingForFactCheckPublishedOnField < ActiveRecord::Migration[6.1]
  def change
    options = {
      index: CheckElasticSearchModel.get_index_alias,
      body: {
        properties: {
          fact_check_published_on: { type: 'long' },
        }
      }
    }
    $repository.client.indices.put_mapping options
  end
end
