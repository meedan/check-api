class AddPartialIndexToTaskAnswers < ActiveRecord::Migration[4.2]
  def change
    add_index :annotations, :annotation_type, name: 'index_annotation_type_order', order: { name: :varchar_pattern_ops }
  end
end
