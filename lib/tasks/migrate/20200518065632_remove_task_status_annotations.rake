namespace :check do
  namespace :migrate do
    task remove_task_status_annotations: :environment do
      # delete task status annotation
      Annotation.where(annotation_type: 'task_status').find_in_batches(:batch_size => 2500) do |data|
        print "."
        ids = data.map(&:id)
        Dynamic.where(id: ids).delete_all
        # delete task_status_status field
        DynamicAnnotation::Field.where(annotation_type: 'task_status', annotation_id: ids, field_name: 'task_status_status').delete_all
      end
      # delete all versions related to `task_status_status` field
      Team.find_each do |t|
        Version.from_partition(t.id).where(item_type: 'DynamicAnnotation::Field')
        .where('version_field_name(event_type, object_after) = ?', 'task_status_status')
        .find_in_batches(:batch_size => 2500) do |versions|
          print "."
          Version.from_partition(t.id).where(id: versions.map(&:id)).delete_all
        end
      end
    end
  end
end
