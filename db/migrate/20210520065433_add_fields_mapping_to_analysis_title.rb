class AddFieldsMappingToAnalysisTitle < ActiveRecord::Migration
  def change
    index_alias = CheckElasticSearchModel.get_index_alias
    client = $repository.client
    options = {
      index: index_alias,
      body: {
        properties: {
          analysis_title: {
            type: 'text',
            analyzer: 'check',
            fields: { raw: { type: 'keyword' } }
          }
        }
      }
    }
    client.indices.put_mapping options
  end
end
