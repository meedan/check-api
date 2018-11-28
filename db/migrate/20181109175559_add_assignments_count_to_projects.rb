class AddAssignmentsCountToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :assignments_count, :integer, default: 0
  end
end
