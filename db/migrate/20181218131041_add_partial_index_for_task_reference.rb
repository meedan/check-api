class AddPartialIndexForTaskReference < ActiveRecord::Migration
  def change
    add_index :dynamic_annotation_fields, :value, name: 'index_task_reference', where: "field_type = 'task_reference'"
  end
end
