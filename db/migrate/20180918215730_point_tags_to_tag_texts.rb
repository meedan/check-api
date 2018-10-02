class PointTagsToTagTexts < ActiveRecord::Migration
  def change
    RequestStore.store[:skip_notifications] = true
    print "Converting #{Tag.length} tags: "
    Tag.where(annotation_type: 'tag').find_each do |tag|
      next unless ['ProjectSource', 'ProjectMedia', 'Source', 'Task'].include?(tag.annotated_type)
      next if tag.annotated && tag.annotated.respond_to?(:archived) && tag.annotated.archived
      next if tag.get_team.empty?
      tag.updated_at = Time.now
      tag.skip_check_ability = true
      tag.skip_notifications = true
      tag.skip_clear_cache = true
      tag.save!
      print '.'
    end
    puts 'Done!'
    RequestStore.store[:skip_notifications] = false
  end
end
