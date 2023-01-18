class AddIndexToFieldName < ActiveRecord::Migration[5.2]
  def change
    add_index :dynamic_annotation_fields, :field_name
  end
end
