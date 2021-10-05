class AddPartialIndexToTranslationRequestId < ActiveRecord::Migration[4.2]
  def up
    execute "CREATE UNIQUE INDEX translation_request_id ON dynamic_annotation_fields (value) WHERE field_name = 'translation_request_id'"
  end

  def down
    execute "DROP INDEX translation_request_id"
  end
end
