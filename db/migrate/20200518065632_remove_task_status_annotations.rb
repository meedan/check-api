class RemoveTaskStatusAnnotations < ActiveRecord::Migration
  def change
    Rails.cache.write('check:migrate:remove_task_status_annotations', ProjectMedia.last&.id)
  end
end
