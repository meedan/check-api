class AddOriginalClaimToMedia < ActiveRecord::Migration[6.1]
  def change
    add_column :medias, :original_claim, :text, null: true
	  add_column :medias, :original_claim_hash, :string, null: true
	  add_index :medias, :original_claim_hash, unique: true
  end
end
