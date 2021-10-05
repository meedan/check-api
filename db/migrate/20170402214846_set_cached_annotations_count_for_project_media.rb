class SetCachedAnnotationsCountForProjectMedia < ActiveRecord::Migration[4.2]
  def change
    ProjectMedia.reset_column_information
    ProjectMedia.find_each do |pm|
      count = pm.get_versions_log.where.not(event_type: 'create_dynamicannotationfield').count
      pm.update_columns(cached_annotations_count: count)
    end
  end
end
