class FixProjectMediaStuckOnPendingSimilarityCheck < ActiveRecord::Migration
  def change
    RequestStore.store[:skip_notifications] = true
    RequestStore.store[:skip_rules] = true
    RequestStore.store[:skip_clear_cache] = true

    # There are just a few items in this condition, so it's fine to run it this way
    # And we need the ElasticSearch callback
    n = ProjectMedia.where(archived: CheckArchivedFlags::FlagCodes::PENDING_SIMILARITY_ANALYSIS).count
    ProjectMedia.where(archived: CheckArchivedFlags::FlagCodes::PENDING_SIMILARITY_ANALYSIS).order('id ASC').each_with_index do |pm, i|
      pm.skip_check_ability = true
      pm.archived = CheckArchivedFlags::FlagCodes::NONE
      pm.save!
      puts "#{i + 1}/#{n}) Done for project media with ID #{pm.id}"
    end

    RequestStore.store[:skip_notifications] = false
    RequestStore.store[:skip_rules] = false
    RequestStore.store[:skip_clear_cache] = false
  end
end
