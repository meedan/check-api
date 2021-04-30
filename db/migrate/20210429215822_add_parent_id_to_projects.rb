class AddParentIdToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :parent_id, :integer
    add_index :projects, :parent_id
  end
end
