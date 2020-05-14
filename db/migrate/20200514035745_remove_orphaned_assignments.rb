class RemoveOrphanedAssignments < ActiveRecord::Migration
  def change
    Rails.cache.write('check:migrate:remove_orphaned_assignments', Assignment.last&.id)
  end
end
