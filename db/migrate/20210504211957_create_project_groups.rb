class CreateProjectGroups < ActiveRecord::Migration
  def change
    create_table :project_groups do |t|
      t.string :title, null: false
      t.integer :team_id, null: false
      t.timestamps null: false
    end
    add_index :project_groups, :team_id
  end
end
