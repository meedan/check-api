class AddQuoteHashToMediaTable < ActiveRecord::Migration[6.1]
  def change
    add_column :medias, :quote_hash, :string
    add_index :medias, :quote_hash
  end
end
