class RemoveVideoArchiverData < ActiveRecord::Migration
  def change
    started = Time.now.to_i
    RequestStore.store[:skip_notifications] = true
    RequestStore.store[:skip_clear_cache] = true
    RequestStore.store[:skip_rules] = true

    n = DynamicAnnotation::Field.where(field_name: 'video_archiver_response').count
    DynamicAnnotation::Field.where(field_name: 'video_archiver_response').destroy_all
    DynamicAnnotation::FieldInstance.where(name: 'video_archiver_response').destroy_all

    minutes = ((Time.now.to_i - started) / 60).to_i
    puts "[#{Time.now}] Done. #{n} video archiver fields removed in #{minutes} minutes."

    RequestStore.store[:skip_notifications] = false
    RequestStore.store[:skip_clear_cache] = false
    RequestStore.store[:skip_rules] = false
  end
end
