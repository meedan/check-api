class AddUniqueIndexForSmoochUserIdField < ActiveRecord::Migration[5.2]
  def change
    loop do
      ids = DynamicAnnotation::Field.select('value')
      .where(annotation_type: "smooch_user", field_name: 'smooch_user_id')
      .group('value').having('COUNT(id) > ?', 1).maximum('id')
      DynamicAnnotation::Field.where(id: ids.values).find_in_batches(:batch_size => 500) do |fields|
        print '.'
        deleted_ids = fields.map(&:id)
        DynamicAnnotation::Field.where(id: deleted_ids).delete_all
      end
      break if ids.blank?
    end
    execute %{CREATE UNIQUE INDEX smooch_user_unique_id ON dynamic_annotation_fields (value) WHERE field_name = 'smooch_user_id' AND value <> '' AND value <> '""'}
  end
end
