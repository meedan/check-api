class CreateExplainerItems < ActiveRecord::Migration[6.1]
  def change
    create_table :explainer_items do |t|
      t.references :explainer, foreign_key: true
      t.references :project_media, foreign_key: true

      t.timestamps
    end
  end
end
