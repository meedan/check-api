namespace :check do
  namespace :migrate do
    desc 'Add blank on description from items with login page message and delete relationships for confirmed similarities create by Alegre Bot'
    task fix_annotation_fields_description: :environment do
      RequestStore.store[:skip_notifications] = true
      started = Time.now.to_i
      last_id = Rails.cache.read('check:migrate:fix_annotation_fields_description:last_id')

      login_page_descriptions = ['log into facebook to start sharing', 'log in to facebook to start sharing', 'see posts, photos and more on facebook']
      total = DynamicAnnotation::Field.where(field_name: 'metadata_value').where("LOWER(value) LIKE ANY (array[?])", login_page_descriptions.map { |description| "%#{description}%" }).joins("INNER JOIN annotations a ON dynamic_annotation_fields.annotation_id = a.id").joins("INNER JOIN medias media ON a.annotated_id = media.id AND a.annotated_type = 'Media'").where("dynamic_annotation_fields.id <= ? ", last_id).count
      puts "[#{Time.now}] Set blank on description from #{total} DynamicAnnotation::Fields"
      field_counter = 0
      skipped = 0
      media_ids = []
      DynamicAnnotation::Field.includes(:annotation).where(field_name: 'metadata_value').where("LOWER(value) LIKE ANY (array[?])", login_page_descriptions.map { |description| "%#{description}%" }).joins("INNER JOIN annotations a ON dynamic_annotation_fields.annotation_id = a.id").joins("INNER JOIN medias media ON a.annotated_id = media.id AND a.annotated_type = 'Media'").where("dynamic_annotation_fields.id <= ? ", last_id).find_each do |field|
        field_counter += 1
        begin
          data = JSON.parse(field.value)
          if data['description'] && login_page_descriptions.find { |pattern| data['description'].downcase.match(pattern) }
            data['description'] = ''
            field.update_columns(value: data.to_json, value_json: data)
            media_ids << field.annotation.annotated_id
            puts "(#{field_counter}/#{total}) [#{Time.now}]"
          end
        rescue StandardError => e
          msg = e.message || 'unknown'
          skipped += 1
          puts "[#{Time.now}] Skipping #{field.id} (because of error #{msg})"
        end
      end
      puts "[#{Time.now}] Finished setting blank on description from DynamicAnnotation::Fields"

      pm_ids = ProjectMedia.where(media_id: media_ids).pluck(:id)

      alegre_bot = BotUser.alegre_user
      r_count = Relationship.where(source_id: pm_ids, user_id: alegre_bot.id).confirmed.count
      puts "[#{Time.now}] Deleting #{r_count} relationships from #{pm_ids.size} project medias related to fixed medias"
      Relationship.where(source_id: pm_ids, user_id: alegre_bot.id).confirmed.delete_all
      puts "[#{Time.now}] Finished deleting relationships"

      puts "[#{Time.now}] Refreshing #{pm_ids.size} ProjectMedia descriptions and updating targets_count and sources_count"
      pm_counter = 0
      ProjectMedia.where(id: pm_ids).find_each do |pm|
        pm_counter += 1
        pm.description(true)
        pm.linked_items_count(true)
        pm_sources_count = Relationship.where(target_id: pm.id).where('relationship_type = ? OR relationship_type = ?', Relationship.confirmed_type.to_yaml, Relationship.suggested_type.to_yaml).count
        pm_targets_count = Relationship.where(source_id: pm.id).where('relationship_type = ? OR relationship_type = ?', Relationship.confirmed_type.to_yaml, Relationship.suggested_type.to_yaml).count
        pm.update_columns(sources_count: pm_sources_count, targets_count: pm_targets_count)
        puts "(#{pm_counter}/#{pm_ids.size}) [#{Time.now}]"
      end
      puts "[#{Time.now}] Finished refreshing ProjectMedia description and updated targets_count and sources_count."

      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done"
      puts "#{total} fields verified, #{field_counter} fields fixed and #{skipped} skipped in #{minutes} minutes."
      puts "#{pm_counter} ProjectMedia descriptions were refreshed and the targets_count and sources_count were updated."
      puts "#{r_count} relationships deleted."
      Rails.cache.delete('check:migrate:fix_annotation_fields_description:last_id')
      RequestStore.store[:skip_notifications] = false
    end
  end
end
