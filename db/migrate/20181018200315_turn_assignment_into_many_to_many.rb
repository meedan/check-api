class TurnAssignmentIntoManyToMany < ActiveRecord::Migration
  def change
    create_table :assignments do |t|
      t.integer :annotation_id, null: false
      t.integer :user_id, null: false
      t.timestamps null: false
    end

    add_index :assignments, :annotation_id
    add_index :assignments, :user_id
    add_index :assignments, [:annotation_id, :user_id], unique: true

    Annotation.where('assigned_to_id IS NOT NULL').find_each do |annotation|
      a = Assignment.new
      a.annotation_id = annotation.id
      a.user_id = annotation.assigned_to_id
      a.save!
    end

    remove_column :annotations, :assigned_to_id
  end
end
