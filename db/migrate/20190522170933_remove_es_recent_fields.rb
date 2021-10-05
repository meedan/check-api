class RemoveEsRecentFields < ActiveRecord::Migration[4.2]
  def change
    # Remember the last project media we need to work on since once this code is deployed,
    # all subsequent new project medias will not include recent_activity and recent_added fields
    Rails.cache.write('check:migrate:remove_es_recent_fields:last_id', ProjectMedia&.last&.id || 0)
  end
end
