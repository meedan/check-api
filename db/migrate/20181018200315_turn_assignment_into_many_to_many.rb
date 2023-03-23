class TurnAssignmentIntoManyToMany < ActiveRecord::Migration[4.2]
  def change  
    create_table :assignments do |t|
      t.integer :assigned_id, null: false, index: true
      t.integer :user_id, null: false, index: true
      t.string :assigned_type, index: true
      t.integer :assigner_id, index: true
      t.text :message
      t.timestamps null: false
    end

    add_index :assignments, [:assigned_id, :assigned_type]
    add_index :assignments, [:assigned_id, :assigned_type, :user_id], unique: true
  end
end
