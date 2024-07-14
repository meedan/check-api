class AddUniqueIndexToExplainerItems < ActiveRecord::Migration[6.1]
  def change
    add_index :explainer_items, [:explainer_id, :project_media_id], unique: true
  end
end
