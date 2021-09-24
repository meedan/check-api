class AddArchivedToProjects < ActiveRecord::Migration[4.2]
  def change
    add_column :projects, :archived, :integer, default: 0
  end
end
