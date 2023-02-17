class CreateClaimDescriptions < ActiveRecord::Migration[5.2]
  def change
    create_table :claim_descriptions do |t|
      t.text :description
      t.references :user, foreign_key: true, null: false
      t.references :project_media, foreign_key: true, null: false
      t.text :context
      t.timestamps
    end
    remove_index :claim_descriptions, name: 'index_claim_descriptions_on_project_media_id'
    add_index :claim_descriptions, :project_media_id, unique: true
  end
end
