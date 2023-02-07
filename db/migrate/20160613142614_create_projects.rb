class CreateProjects < ActiveRecord::Migration[4.2]
  def change
    create_table :projects do |t|
      t.belongs_to :user
      t.belongs_to :team, index: true
      t.belongs_to :project_group, index: true
      t.string :title
      t.boolean :is_default, default: false, index: true
      t.text :description
      t.string :lead_image
      t.string :token, unique: true
      t.integer :assignments_count, default: 0
      t.integer :privacy, default: 0, null: false, index: true
      t.integer :archived, default: 0
      t.text :settings
      t.timestamps null: false
    end
    add_index :projects, :id
  end
end
