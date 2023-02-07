class CreateClaimDescriptions < ActiveRecord::Migration[5.2]
  def change
    create_table :claim_descriptions do |t|
      t.text :description
      t.references :user, foreign_key: true, null: false
      t.references :project_media, foreign_key: true, null: false, unique: true
      t.text :context
      t.timestamps
    end
  end
end
