class AddQuoteToMedia < ActiveRecord::Migration[4.2]
  def change
    add_column :medias, :quote, :string
  end
end
