class ReindexEsForAccentsAndNonLatin < ActiveRecord::Migration
  def change
    MediaSearch.reindex_es_data
  end
end
