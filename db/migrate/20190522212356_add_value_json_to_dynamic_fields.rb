class AddValueJsonToDynamicFields < ActiveRecord::Migration
  def change
    add_column :dynamic_annotation_fields, :value_json, :jsonb, default: '{}'
    add_index :dynamic_annotation_fields, :value_json, using: :gin
  end
end
