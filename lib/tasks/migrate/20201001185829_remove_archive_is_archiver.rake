namespace :check do
  namespace :migrate do
    task remove_archive_is_archiver: :environment do
      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil

      started = Time.now.to_i
      RequestStore.store[:skip_notifications] = true
      RequestStore.store[:skip_clear_cache] = true
      RequestStore.store[:skip_rules] = true

      # Remove Archive.is from bot and bot installations
      bot = BotUser.find_by(login: 'keep')
      unless bot.nil?
        bot.settings[:settings].delete_if { |s| s['name'] == 'archive_archive_is_enabled' }
        bot.save!
        n = 0
        TeamBotInstallation.where(user_id: bot.id).each do |tb|
          settings = tb.settings.with_indifferent_access
          if settings.has_key?(:archive_archive_is_enabled)
            settings.delete(:archive_archive_is_enabled)
            tb.settings = settings
            tb.save!
            n += 1
          end
        end
      end
      puts "[#{Time.now}] Removed Archive.is from #{n} Keep Bot installations..."

      # Remove Archive.is responses fields
      i = 0
      SIZE = 5000
      field_name = 'archive_is_response'
      n = DynamicAnnotation::Field.where(field_name: field_name).count
      puts "[#{Time.now}] Deleting #{n} #{field_name} fields..."

      query = "SELECT f.id, pm.team_id FROM dynamic_annotation_fields f LEFT OUTER JOIN annotations a ON a.id = f.annotation_id LEFT OUTER JOIN project_medias pm ON pm.id = a.annotated_id WHERE f.field_name = '#{field_name}' AND a.annotation_type = 'archiver' AND a.annotated_type = 'ProjectMedia' ORDER BY f.id LIMIT #{SIZE}"
      result = ActiveRecord::Base.connection.execute(query).to_a
      while !result.empty? do
        fields_to_delete = []
        result.group_by { |r| r['team_id'] }.each do |team_id, fields|
          fields_to_delete += fields.map { |f| f['id'] }
          Version.from_partition(team_id.to_i).where(item_id: fields_to_delete).delete_all
        end
        i += fields_to_delete.size
        DynamicAnnotation::Field.where(id: fields_to_delete).delete_all
        puts "[#{Time.now}] Deleted #{i}/#{n} #{field_name} fields..."
        query = "SELECT f.id, pm.team_id FROM dynamic_annotation_fields f LEFT OUTER JOIN annotations a ON a.id = f.annotation_id LEFT OUTER JOIN project_medias pm ON pm.id = a.annotated_id WHERE f.field_name = '#{field_name}' AND a.annotation_type = 'archiver' AND a.annotated_type = 'ProjectMedia' ORDER BY f.id LIMIT #{SIZE}"
        result = ActiveRecord::Base.connection.execute(query).to_a
      end

      DynamicAnnotation::FieldInstance.where(name: field_name).destroy_all

      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done. #{n} Archiver.is fields were removed."

      RequestStore.store[:skip_notifications] = false
      RequestStore.store[:skip_clear_cache] = false
      RequestStore.store[:skip_rules] = false
      ActiveRecord::Base.logger = old_logger
    end
  end
end
