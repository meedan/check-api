class AddAssignerToAssignment < ActiveRecord::Migration[4.2]
  def change
  	add_column :assignments, :assigner_id, :integer
  	add_index :assignments, :assigner_id
  end
end
