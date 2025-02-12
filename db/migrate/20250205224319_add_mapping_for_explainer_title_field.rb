class AddMappingForExplainerTitleField < ActiveRecord::Migration[6.1]
  def change
    options = {
      index: CheckElasticSearchModel.get_index_alias,
      body: {
        properties: {
          explainer_title: { type: 'text', analyzer: 'check' },
        }
      }
    }
    $repository.client.indices.put_mapping options
  end
end
