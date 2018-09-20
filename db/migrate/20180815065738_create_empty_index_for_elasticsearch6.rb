class CreateEmptyIndexForElasticsearch6 < ActiveRecord::Migration
  def change
  	MediaSearch.delete_index
    client = MediaSearch.gateway.client
    index_a = CheckElasticSearchModel.get_index_alias
    if client.indices.exists? index: index_a
    	say "You must delete the existing index or alias [#{CheckElasticSearchModel.get_index_alias}] before running a migration."
    else
    	MediaSearch.create_index
    end
    say "You should run a rake task `bundle exec rake check:create_es_data_from_pg` to re-index existing data."
  end
end