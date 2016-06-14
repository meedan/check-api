class CreateProjectSources < ActiveRecord::Migration
  def change
    create_table :project_sources do |t|
      t.belongs_to :project, index: true
      t.belongs_to :source, index: true
      t.timestamps null: false
    end
  end
end
