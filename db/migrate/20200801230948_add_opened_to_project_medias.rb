class AddOpenedToProjectMedias < ActiveRecord::Migration[4.2]
  def change
    add_column :project_medias, :opened, :boolean, default: false, null: false
  end
end
