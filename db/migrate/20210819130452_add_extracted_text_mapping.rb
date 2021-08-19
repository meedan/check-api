class AddExtractedTextMapping < ActiveRecord::Migration
  def change
    index_alias = CheckElasticSearchModel.get_index_alias
    client = $repository.client
    options = {
      index: index_alias,
      body: {
        properties: {
          extracted_text: { type: 'text', analyzer: 'check' }
        }
      }
    }
    client.indices.put_mapping options
  end
end
