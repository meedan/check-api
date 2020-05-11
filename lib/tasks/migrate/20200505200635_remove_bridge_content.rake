namespace :check do
  namespace :migrate do
    task remove_bridge_content: :environment do
      started = Time.now.to_i
      i = 0
      skipped = 0
      annotation_types = ['mt', 'translation_request', 'translation_status', 'translation']
      team_ids = ActiveRecord::Base.connection.execute("
        select distinct(pm.team_id) from annotations a inner join project_medias pm on a.annotated_id = pm.id
        where a.annotated_type = 'ProjectMedia' and a.annotation_type in ('#{annotation_types.join("','")}')
      ").collect{ |t| t["team_id"].to_i }
      n = team_ids.count + 4
      progressbar = ProgressBar.create(:total => n)
      RequestStore.store[:skip_notifications] = true
      RequestStore.store[:skip_clear_cache] = true

      team_ids.each { |t|
        progressbar.increment
        annotation_ids = ActiveRecord::Base.connection.execute("
          select a.id from annotations a inner join project_medias pm on a.annotated_id = pm.id
          where a.annotated_type = 'ProjectMedia' and a.annotation_type in ('#{annotation_types.join("','")}')
          and pm.team_id = #{t}
        ").collect{ |t| t["id"] }
        Version.from_partition(t).where(item_type: 'Dynamic', item_id: annotation_ids).delete_all
        field_ids = ActiveRecord::Base.connection.execute("
          select f.id from dynamic_annotation_fields f left join annotations a on f.annotation_id = a.id
          where a.id in (#{annotation_ids.join(',')})
        ").collect{ |f| f["id"] }
        Version.from_partition(t).where(item_type: 'DynamicAnnotation::Field', item_id: field_ids).delete_all
      }

      progressbar.increment
      Dynamic.where('annotation_type in (?)', annotation_types).delete_all
      progressbar.increment
      DynamicAnnotation::Field.where('annotation_type in (?)', annotation_types).delete_all
      progressbar.increment
      DynamicAnnotation::AnnotationType.where('annotation_type in (?)', annotation_types).destroy_all
      progressbar.increment
      DynamicAnnotation::FieldInstance.where('annotation_type in (?)', annotation_types).destroy_all

      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done. #{n} removed and #{skipped} skipped in #{minutes} minutes."
      Rails.cache.delete('check:migrate:remove_bridge_content:last_id')
      RequestStore.store[:skip_notifications] = false
      RequestStore.store[:skip_clear_cache] = false
    end
  end
end
