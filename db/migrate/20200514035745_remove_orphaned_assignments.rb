class RemoveOrphanedAssignments < ActiveRecord::Migration[4.2]
  def change
    Rails.cache.write('check:migrate:remove_orphaned_assignments', Assignment.last&.id)
  end
end
