class AddInactiveToProjectMedia < ActiveRecord::Migration[4.2]
  def change
    add_column :project_medias, :inactive, :boolean, default: false
    add_index :project_medias, :inactive
  end
end
