class CleanupTaskReferences < ActiveRecord::Migration[4.2]
  def change
    DynamicAnnotation::Field.where(:field_type => 'task_reference').delete_all
    DynamicAnnotation::FieldInstance.where(:field_type => 'task_reference').delete_all
    DynamicAnnotation::FieldType.where(:field_type => 'task_reference').delete_all
  end
end
