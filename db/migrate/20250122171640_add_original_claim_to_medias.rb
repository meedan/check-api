class AddOriginalClaimToMedias < ActiveRecord::Migration[6.1]
  def change
    add_column :medias, :original_claim, :string, null: true
    add_index :medias, :original_claim, unique: true
  end
end
