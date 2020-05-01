namespace :check do
  namespace :migrate do
    task remove_memebuster_data: :environment do
      last_id = Rails.cache.read('check:migrate:remove_memebuster_data:last_id')
      raise "No last_id found in cache for check:remove_memebuster_data! Aborting." if last_id.nil?
      i = 0
      skipped = 0
      started = Time.now.to_i
      n = Dynamic.where(annotation_type: 'memebuster').where('id < ?', last_id).count
      RequestStore.store[:skip_notifications] = true
      RequestStore.store[:skip_clear_cache] = true
      Dynamic.where(annotation_type: 'memebuster').where('id < ?', last_id).find_each do |a|
        begin
          i += 1
          a.destroy!
          puts "#{i}/#{n}) [#{Time.now}] Removed"
        rescue Exception => e
          msg = e.message || 'unknown'
          skipped += 1
          puts "#{i}/#{n}) [#{Time.now}] Skipping (because of error #{msg})"
        end
      end
      DynamicAnnotation::AnnotationType.where(annotation_type: 'memebuster').last.destroy!
      DynamicAnnotation::FieldInstance.where("name LIKE 'memebuster_%'").each{ |f| f.destroy! }
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done. #{n} removed and #{skipped} skipped in #{minutes} minutes."
      Rails.cache.delete('check:migrate:remove_memebuster_data:last_id')
      RequestStore.store[:skip_notifications] = false
      RequestStore.store[:skip_clear_cache] = false
    end
  end
end
