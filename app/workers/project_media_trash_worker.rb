class ProjectMediaTrashWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'trash', retry: 0

  def perform(id, options)
    options = begin YAML::load(options) rescue {} end
    # Check item still exists and Trashed
    type = options[:type] || 'trash'
    archived = type == 'trash' ? CheckArchivedFlags::FlagCodes::TRASHED : CheckArchivedFlags::FlagCodes::SPAM
    pm = ProjectMedia.where(id: id, archived: archived).last
    if !pm.nil? && pm.updated_at.to_i <= options[:updated_at].to_i
      should_delete = true
      if type == 'spam'
        extra = options[:extra] || {}
        # Verify that relationship still exists
        should_delete = Relationship.where(
          source_id: extra.with_indifferent_access[:parent_id],
          target_id: pm.id
        ).exists?
      end
      if should_delete
        begin
          pm.destroy!
        rescue StandardError => e
          pm.class.notify_error(e, { item_type: pm.class.name, item_id: pm.id }, RequestStore[:request])
        end
      end
    end
  end
end
