class ChangePartialIndexForTaskReference < ActiveRecord::Migration
  def change
    remove_index :dynamic_annotation_fields, name: 'index_task_reference'
    execute "CREATE INDEX index_task_reference ON dynamic_annotation_fields (CAST(REGEXP_REPLACE(value,'[^0-9]+','','g') AS INTEGER)) WHERE field_type = 'task_reference'"
  end
end
