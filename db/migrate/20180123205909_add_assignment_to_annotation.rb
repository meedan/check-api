class AddAssignmentToAnnotation < ActiveRecord::Migration[4.2]
  def change
    add_column :annotations, :assigned_to_id, :integer
    add_index :annotations, :assigned_to_id
  end
end
