class AddAssignmentToAnnotation < ActiveRecord::Migration
  def change
    add_column :annotations, :assigned_to_id, :integer
    add_index :annotations, :assigned_to_id
  end
end
