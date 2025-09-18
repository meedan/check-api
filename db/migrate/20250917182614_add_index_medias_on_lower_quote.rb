class AddIndexMediasOnLowerQuote < ActiveRecord::Migration[6.1]
  def up
    execute <<-SQL
      CREATE INDEX index_medias_on_lower_quote
      ON medias USING hash (LOWER(quote))
      WHERE type = 'Claim';
    SQL
  end

  def down
    execute <<-SQL
      DROP INDEX IF EXISTS index_medias_on_lower_quote;
    SQL
  end
end
