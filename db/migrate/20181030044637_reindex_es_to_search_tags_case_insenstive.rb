class ReindexEsToSearchTagsCaseInsenstive < ActiveRecord::Migration[4.2]
  def change
  	CheckElasticSearchModel.reindex_es_data
  end
end
