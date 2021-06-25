class AddJsonSchemaToAnnotations < ActiveRecord::Migration[4.2]
  def change
    add_column :dynamic_annotation_annotation_types, :json_schema, :jsonb
    add_index :dynamic_annotation_annotation_types, :json_schema, using: :gin
  end
end
