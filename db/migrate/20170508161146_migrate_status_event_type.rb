class MigrateStatusEventType < ActiveRecord::Migration[4.2]
  def change
    unless defined?(Status).nil?
      status_list = PaperTrail::Version.where(event_type: 'create_status').group(:item_id).count.select{ |id, count| count > 1 }
      status_list.each do |id, c|
        s = Status.where(id: id).last
        unless s.nil?
          ids = s.versions.map(&:id).sort
          # Remove first log entry
          ids.shift
          PaperTrail::Version.where(id: ids).update_all(event_type: 'update_status', event: 'update', project_media_id: s.annotated_id)
        end
      end
    end
  end
end
