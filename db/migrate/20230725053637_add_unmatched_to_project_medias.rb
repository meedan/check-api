class AddUnmatchedToProjectMedias < ActiveRecord::Migration[6.1]
  def change
    add_column :project_medias, :unmatched, :integer, default: 0
    add_index :project_medias, :unmatched
    # add mapping for unmatched
    index_alias = CheckElasticSearchModel.get_index_alias
    client = $repository.client
    options = {
      index: index_alias,
      body: {
        properties: {
          unmatched: { type: 'long' },
        }
      }
    }
    client.indices.put_mapping options
  end
end
