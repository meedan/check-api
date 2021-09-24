class RemoveProjectIdFromProjectMedia < ActiveRecord::Migration[4.2]
  def change
  	remove_column :project_medias, :project_id
  end
end
