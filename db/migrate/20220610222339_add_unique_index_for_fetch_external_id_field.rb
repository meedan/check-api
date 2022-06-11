class AddUniqueIndexForFetchExternalIdField < ActiveRecord::Migration[5.2]
  def change
    execute %{CREATE UNIQUE INDEX fetch_unique_id ON dynamic_annotation_fields (value) WHERE field_name = 'external_id' AND value <> '' AND value <> '""'}
  end
end
