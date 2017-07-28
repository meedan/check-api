class AddEsMappingForAccount < ActiveRecord::Migration
  def change
    return if Rails.env === 'test'
    client = MediaSearch.gateway.client
    client.indices.put_mapping index: MediaSearch.index_name, type: 'account_search', body: AccountSearch.mappings.to_hash
  end
end
