class AddClaimsAndFactChecksMapping < ActiveRecord::Migration[5.2]
  def change
    index_alias = CheckElasticSearchModel.get_index_alias
    client = $repository.client
    options = {
      index: index_alias,
      body: {
        properties: {
          claim_description_content: { type: 'text', analyzer: 'check' },
          fact_check_title: { type: 'text', analyzer: 'check' },
          fact_check_summary: { type: 'text', analyzer: 'check' }
        }
      }
    }
    client.indices.put_mapping options
  end
end
