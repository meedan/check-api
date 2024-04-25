class CreateExplainers < ActiveRecord::Migration[6.1]
  def change
    create_table :explainers do |t|
      t.string :title
      t.text :description
      t.string :url
      t.string :language
      t.references :user, foreign_key: true, null: false
      t.references :team, foreign_key: true, null: false

      t.timestamps
    end
  end
end
