class AddArchivedToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :archived, :integer, default: 0
  end
end
