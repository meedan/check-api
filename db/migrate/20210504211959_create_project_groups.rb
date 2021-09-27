class CreateProjectGroups < ActiveRecord::Migration[4.2]
  def change
    create_table :project_groups do |t|
      t.string :title, null: false
      t.text :description
      t.integer :team_id, null: false
      t.timestamps null: false
    end
    add_index :project_groups, :team_id
  end
end
