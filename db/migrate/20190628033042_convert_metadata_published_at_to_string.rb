class ConvertMetadataPublishedAtToString < ActiveRecord::Migration[4.2]
  def change
    # Remember the last metadata annotation we need to verify on since this code is deployed,
    # all subsequent `published_at` info on metadata annotation will be String.
    Rails.cache.write('check:migrate:convert_metadata_published_at_to_string:last_id', DynamicAnnotation::Field.where(field_name: 'metadata_value')&.last&.id || 0)
  end
end
