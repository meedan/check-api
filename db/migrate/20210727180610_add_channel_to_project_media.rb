class AddChannelToProjectMedia < ActiveRecord::Migration[4.2]
  def change
    add_column :project_medias, :channel, :integer, default: 0
    add_index :project_medias, :channel
    # add ES mapping
    index_alias = CheckElasticSearchModel.get_index_alias
    client = $repository.client
    options = {
      index: index_alias,
      body: {
        properties: {
          channel: { type: 'integer' }
        }
      }
    }
    client.indices.put_mapping options
  end
end
