require 'active_support/concern'

module ProjectMediaExport
  extend ActiveSupport::Concern

  def media_content
    self.media.quote || self.embed['description']
  end

  def tags_list
    self.get_annotations('tag').to_enum.reverse_each.collect{ |t| t.data['full_tag'] }.reverse.join(', ')
  end

  def tasks_resolved_count
    self.get_annotations('task').select{ |t| t.status === "Resolved" }.count
  end

  def contributing_users_count
    self.annotations.where(annotator_type: 'User').group_by(&:annotator_id).size
  end

  def time_to_status(position)
    statuses_log = self.get_versions_log.where(event_type: 'update_status')
    return '' if statuses_log.empty? || (statuses_log.size == 1 && position == :first)
    (statuses_log.send(position).created_at - self.created_at).to_i
  end

end
