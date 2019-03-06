class CleanupTaskReferences < ActiveRecord::Migration
  def change
    DynamicAnnotation::Field.delete_all(:field_type => 'task_reference')
    DynamicAnnotation::FieldInstance.delete_all(:field_type => 'task_reference')
    DynamicAnnotation::FieldType.delete_all(:field_type => 'task_reference')
  end
end
