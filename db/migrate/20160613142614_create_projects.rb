class CreateProjects < ActiveRecord::Migration[4.2]
  def change
    create_table :projects do |t|
      t.belongs_to :user, index: true
      t.belongs_to :team, index: true
      t.string :title
      t.text :description
      t.string :lead_image
      t.timestamps null: false
    end
  end
end
