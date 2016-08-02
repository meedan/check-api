class CreateProjectMedias < ActiveRecord::Migration
  def change
    create_table :project_medias do |t|
      t.belongs_to :project, index: true
      t.belongs_to :media, index: true
      t.timestamps null: false
    end
  end
end
