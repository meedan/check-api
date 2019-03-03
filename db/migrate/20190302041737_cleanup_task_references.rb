class CleanupTaskReferences < ActiveRecord::Migration
  def change
    DynamicAnnotation::FieldInstance.where(:field_type => 'task_reference').destroy_all
    DynamicAnnotation::Field.where(:field_type => 'task_reference').destroy_all
    DynamicAnnotation::FieldType.where(:field_type => 'task_reference').destroy_all
  end
end
