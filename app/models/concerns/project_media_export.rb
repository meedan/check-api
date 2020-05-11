require 'active_support/concern'

module ProjectMediaExport
  extend ActiveSupport::Concern

  def media_content
    self.media.quote || self.metadata['description']
  end

  def tags_list
    self.get_annotations('tag').to_enum.reverse_each.collect{ |t| t.load.tag_text }.reverse.join(', ')
  end

  def contributing_users_count
    self.annotations.where(annotator_type: 'User').group_by(&:annotator_id).size
  end

  def time_to_status(position)
    default = self.default_project_media_status_type
    statuses_log = self.get_versions_log.where(event_type: 'update_dynamicannotationfield').select{ |version| JSON.parse(version.object_after)['annotation_type'] == default }
    return '' if statuses_log.empty? || (statuses_log.size == 1 && position == :first)
    (statuses_log.send(position).created_at - self.created_at).to_i
  end
end
