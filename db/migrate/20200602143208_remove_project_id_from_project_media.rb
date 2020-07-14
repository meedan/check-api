class RemoveProjectIdFromProjectMedia < ActiveRecord::Migration
  def change
  	remove_column :project_medias, :project_id
  end
end
