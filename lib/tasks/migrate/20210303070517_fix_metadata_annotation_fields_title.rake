namespace :check do
  namespace :migrate do
    task fix_metadata_annotation_fields_title: :environment do
      RequestStore.store[:skip_notifications] = true
      started = Time.now.to_i
      last_id = Rails.cache.read('check:migrate:fix_metadata_annotation_fields_title:last_id')
      login_page_titles = ['log in or sign up to view', 'log into facebook', 'log in to facebook', 'on facebook']
      total = DynamicAnnotation::Field.where(field_name: 'metadata_value').where("LOWER(value) LIKE ANY (array[?])", login_page_titles.map { |title| "%#{title}%" }).joins("INNER JOIN annotations a ON dynamic_annotation_fields.annotation_id = a.id").joins("INNER JOIN medias media ON a.annotated_id = media.id AND a.annotated_type = 'Media'").count

      puts "[#{Time.now}] Replacing title by url on value column from #{total} DynamicAnnotation::Fields"
      field_counter = 0
      skipped = 0
      media_ids = []
      DynamicAnnotation::Field.includes(:annotation).where(field_name: 'metadata_value').where("LOWER(value) LIKE ANY (array[?])", login_page_titles.map { |title| "%#{title}%" }).joins("INNER JOIN annotations a ON dynamic_annotation_fields.annotation_id = a.id").joins("INNER JOIN medias media ON a.annotated_id = media.id AND a.annotated_type = 'Media'").where("dynamic_annotation_fields.id <= ? ", last_id).find_each do |field|
        field_counter += 1
        begin
          data = JSON.parse(field.value)
          if data['title'] && login_page_titles.find { |pattern| data['title'].downcase.match(pattern) }
            url = data['url']
            match = url.match(/https:\/\/www.facebook.com\/login\/\?next=(.+)/)
            url = URI.decode(match[1]) if match && match[1]
            data['title'] = url
            field.update_columns(value: data.to_json, value_json: data)
            media_ids << field.annotation.annotated_id
            puts "(#{field_counter}/#{total}) [#{Time.now}]"
          end
        rescue Exception => e
          msg = e.message || 'unknown'
          skipped += 1
          puts "[#{Time.now}] Skipping #{field.id} (because of error #{msg})"
        end
      end
      puts "[#{Time.now}] Finished replacing title by url on value column from DynamicAnnotation::Fields"

      puts "[#{Time.now}] Refreshing #{media_ids.size} ProjectMedia titles"
      pm_counter = 0
      pm_count = ProjectMedia.where(media_id: media_ids).count
      ProjectMedia.where(media_id: media_ids).find_each do |pm|
        pm_counter += 1
        pm.title(true)
        puts "(#{pm_counter}/#{pm_count}) [#{Time.now}]"
      end
      puts "[#{Time.now}] Finished refreshing ProjectMedia titles"

      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done"
      puts "#{total} fields verified, #{field_counter} fields fixed and #{skipped} skipped in #{minutes} minutes."
      puts "#{pm_counter} ProjectMedia titles refreshed."
      Rails.cache.delete('check:migrate:fix_metadata_annotation_fields_title:last_id')
      RequestStore.store[:skip_notifications] = false
    end
  end
end
