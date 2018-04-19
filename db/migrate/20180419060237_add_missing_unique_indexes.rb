class AddMissingUniqueIndexes < ActiveRecord::Migration
  def change
  	add_index :project_sources, [:project_id, :source_id], unique: true
  	add_index :account_sources, [:account_id, :source_id], unique: true
  	add_index :claim_sources, [:media_id, :source_id], unique: true
  	add_index :project_medias, [:project_id, :media_id], unique: true
  end
end
