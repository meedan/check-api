class CreateFactChecks < ActiveRecord::Migration[5.2]
  def change
    create_table :fact_checks do |t|
      t.text :summary
      t.string :url
      t.string :title
      t.references :user, foreign_key: true, null: false, index: true
      t.references :claim_description, foreign_key: true, null: false, index: true, unique: true
      t.string :language, null: false, default: "", index: true
      t.timestamps
    end
    remove_index :fact_checks, name: "index_fact_checks_on_claim_description_id"
    add_index :fact_checks, :claim_description_id, unique: true
  end
end
