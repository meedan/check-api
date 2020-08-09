class AddOpenedToProjectMedias < ActiveRecord::Migration
  def change
    add_column :project_medias, :opened, :boolean, default: false, null: false
  end
end
