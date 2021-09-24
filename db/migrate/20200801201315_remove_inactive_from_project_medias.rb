class RemoveInactiveFromProjectMedias < ActiveRecord::Migration[4.2]
  def change
    remove_column :project_medias, :inactive
  end
end
