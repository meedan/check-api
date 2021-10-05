class AddSmoochCountIndex < ActiveRecord::Migration[4.2]
  def change
    # No schema changes here, only need to call ES reindexing on all `smooch` annotations.
    # Remember the last project media we need to work on since once this code is deployed,
    # all subsequent annotations on new project medias will be properly indexed and
    # all subsequent annotations on existent project medias will be considered when running the task
    Rails.cache.write('check:migrate:add_smooch_annotations_index:last_id', ProjectMedia&.last&.id || 0)
  end
end
