class CreateClaimDescriptions < ActiveRecord::Migration[5.2]
  def change
    create_table :claim_descriptions do |t|
      t.text :description
      t.references :user, foreign_key: true, null: false
      t.references :project_media, foreign_key: true, null: false
      t.text :context
      t.timestamps
    end
    add_index :claim_descriptions, :project_media_id, unique: true
    add_index :claim_descriptions, :user_id
  end
end
