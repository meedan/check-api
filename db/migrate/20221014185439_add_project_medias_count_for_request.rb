class AddProjectMediasCountForRequest < ActiveRecord::Migration[5.2]
  def change
    add_column :requests, :project_medias_count, :integer, null: false, default: 0
  end
end
