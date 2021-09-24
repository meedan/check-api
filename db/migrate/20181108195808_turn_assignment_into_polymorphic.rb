class TurnAssignmentIntoPolymorphic < ActiveRecord::Migration[4.2]
  def change
    rename_column :assignments, :annotation_id, :assigned_id
    add_column :assignments, :assigned_type, :string
    Assignment.find_each do |a|
      a.update_column(:assigned_type, 'Annotation')
    end
    remove_index :assignments, name: 'index_assignments_on_assigned_id_and_user_id'
    add_index :assignments, :assigned_type
    add_index :assignments, [:assigned_id, :assigned_type]
    add_index :assignments, [:assigned_id, :assigned_type, :user_id], unique: true
  end
end
