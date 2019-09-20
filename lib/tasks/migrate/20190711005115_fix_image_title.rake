namespace :check do
  namespace :migrate do
    task fix_image_title: :environment do
      last_id = Rails.cache.read('check:migrate:fix_image_title:last_id')
      raise "No last_id found in cache for check:fix_image_title! Aborting." if last_id.nil?

      i = 0
      total = 0
      n = Version.joins("INNER JOIN annotations a ON a.id::text = versions.item_id AND versions.item_type = 'Annotation' INNER JOIN project_medias pm ON pm.id = a.annotated_id AND a.annotated_type = 'ProjectMedia' AND a.annotation_type = 'metadata' INNER JOIN medias m ON m.id = pm.media_id AND m.type = 'UploadedImage'").where('pm.id <= ?', last_id).group('pm.id, versions.id').count.size
      Version.select('MAX(versions.id) AS maxvid').joins("INNER JOIN annotations a ON a.id::text = versions.item_id AND versions.item_type = 'Annotation' INNER JOIN project_medias pm ON pm.id = a.annotated_id AND a.annotated_type = 'ProjectMedia' AND a.annotation_type = 'metadata' INNER JOIN medias m ON m.id = pm.media_id AND m.type = 'UploadedImage'").where('pm.id <= ?', last_id).group('versions.item_id').each do |v|
        i += 1
        v = Version.find(v.maxvid)
        begin
          changed = false
          o = JSON.parse(v['object_after'])['data']
          if o['title'] != o['embed']['title']
            d = Dynamic.find(v.item_id)
            data = JSON.parse(d.get_field_value('metadata_value'))
            if o['title'] != data['title']

              data['title'] = o['title']
              d.set_fields = { metadata_value: data.to_json }.to_json
              d.skip_notifications = true
              d.save(validate: false)

              changed = true
              total += 1
              puts "#{i}/#{n}) Changing"
            end
          end
          puts "#{i}/#{n}) Parsing" unless changed
        rescue Exception => e
          msg = e.message || 'unknown'
          puts "#{i}/#{n}) Skipping (because of error #{msg})"
        end
      end
      puts "Done. #{total} changed."

      Rails.cache.delete('check:migrate:fix_image_title:last_id')
    end
  end
end
