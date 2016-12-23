class AddQuoteToMedia < ActiveRecord::Migration
  def change
    add_column :medias, :quote, :string
  end
end
