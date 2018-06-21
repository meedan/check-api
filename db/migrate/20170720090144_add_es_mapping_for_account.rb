class AddEsMappingForAccount < ActiveRecord::Migration
  def change
    return if Rails.env === 'test'
    client = MediaSearch.gateway.client
    index_name = CheckElasticSearchModel.get_index_name
    index_alias = CheckElasticSearchModel.get_index_alias
    if client.indices.exists_alias? name: index_alias
      alias_info = client.indices.get_alias name: index_alias
      index_name = alias_info.keys.first
    end
    client.indices.put_mapping index: index_name, type: 'account_search', body: AccountSearch.mappings.to_hash
  end
end
