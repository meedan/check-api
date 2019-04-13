class AddSmoochAnnotationsIndex < ActiveRecord::Migration
  def change
    # No schema changes here, only need to call ES reindexing on all `smooch` annotations.
    # Remember the last annotation we need to work on since once this code is deployed,
    # all subsequent annotations will be properly indexed.
    Rails.cache.write('check:migrate:add_smooch_annotations_index:last_id', Dynamic.where(annotation_type: 'smooch')&.last&.id || 0)
  end
end
