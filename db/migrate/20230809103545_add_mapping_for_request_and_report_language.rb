class AddMappingForRequestAndReportLanguage < ActiveRecord::Migration[6.1]
  def change
    index_alias = CheckElasticSearchModel.get_index_alias
    client = $repository.client
    options = {
      index: index_alias,
      body: {
        properties: {
          report_language: { type: 'keyword', normalizer: 'check' },
          requests: {
            type: 'nested',
            properties: {
              language: { type: 'keyword', normalizer: 'check' },
            }
          },
        }
      }
    }
    client.indices.put_mapping options
  end
end
