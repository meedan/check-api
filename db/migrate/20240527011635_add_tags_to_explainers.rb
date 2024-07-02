class AddTagsToExplainers < ActiveRecord::Migration[6.1]
  def change
    add_column :explainers, :tags, :string, array: true, default: []
    add_index :explainers, :tags, using: 'gin'
  end
end
