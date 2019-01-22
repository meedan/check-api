class RemoveTaskFieldsAndPartialIndex < ActiveRecord::Migration
  def change
    remove_index :dynamic_annotation_fields, name: 'index_task_reference'
  end
end
