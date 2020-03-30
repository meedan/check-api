class AddJsonSchemaToAnnotations < ActiveRecord::Migration
  def change
    add_column :dynamic_annotation_annotation_types, :json_schema, :jsonb
    add_index :dynamic_annotation_annotation_types, :json_schema, using: :gin
  end
end
