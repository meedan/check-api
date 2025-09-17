class AddIndexMediasOnLowerQuote < ActiveRecord::Migration[6.1]
  def change
    add_index :medias, "LOWER(quote)", name: "index_medias_on_lower_quote", where: "type = 'Claim'"
  end
end
