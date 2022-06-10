class AddUniqueIndexForFetchExternalIdField < ActiveRecord::Migration[5.2]
  def change
    add_index :dynamic_annotation_fields, :value, name: 'index_fetch_unique_id', unique: true, where: "field_name = 'external_id'"
  end
end
