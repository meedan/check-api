class AddAssignmentsCountToProjects < ActiveRecord::Migration[4.2]
  def change
    add_column :projects, :assignments_count, :integer, default: 0
  end
end
