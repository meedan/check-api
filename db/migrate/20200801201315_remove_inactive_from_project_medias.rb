class RemoveInactiveFromProjectMedias < ActiveRecord::Migration
  def change
    remove_column :project_medias, :inactive
  end
end
