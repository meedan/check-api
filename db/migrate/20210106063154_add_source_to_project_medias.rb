class AddSourceToProjectMedias < ActiveRecord::Migration
  def change
  	# remove_column :accounts, :team_id
  	add_column :project_medias, :source_id, :integer
    add_index :project_medias, :source_id
    # add ES mapping
    index_alias = CheckElasticSearchModel.get_index_alias
    client = $repository.client
    options = {
      index: index_alias,
      body: {
        properties: {
          source_id: { type: 'integer' }
        }
      }
    }
    client.indices.put_mapping options
  end
end
