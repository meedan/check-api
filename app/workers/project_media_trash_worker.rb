class ProjectMediaTrashWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'trash', retry: 0

  def perform(type, updated_at, id, extra = {})
    # Check item still exists and Trashed
    archived = type == 'trash' ? CheckArchivedFlags::FlagCodes::TRASHED : CheckArchivedFlags::FlagCodes::SPAM
    pm = ProjectMedia.where(id: id, archived: archived).where('updated_at <= ?', updated_at).last
    unless pm.nil?
      should_delete = true
      if type == 'spam'
        # Verify that relationship still exists
        should_delete = Relationship.where(
          source_id: extra.with_indifferent_access[:parent_id],
          target_id: pm.id
        ).exists?
      end
      pm.destroy if should_delete
    end
  end
end
