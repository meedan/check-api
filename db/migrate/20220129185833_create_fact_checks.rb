class CreateFactChecks < ActiveRecord::Migration[5.2]
  def change
    create_table :fact_checks do |t|
      t.text :summary, null: false
      t.string :url
      t.string :title, null: false
      t.references :user, foreign_key: true, null: false
      t.references :claim_description, foreign_key: true, null: false
      t.timestamps
    end
  end
end
