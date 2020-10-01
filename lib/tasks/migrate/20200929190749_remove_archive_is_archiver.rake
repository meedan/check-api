namespace :check do
  namespace :migrate do
    task remove_archive_is_archiver: :environment do
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

      query = "SELECT f.id FROM dynamic_annotation_fields f WHERE f.field_name = '#{field_name}' ORDER BY f.id ASC LIMIT #{SIZE}"
      result = ActiveRecord::Base.connection.execute(query).to_a
      while !result.empty? do
        fields_to_delete = result.map { |r| r['id'] }
        DynamicAnnotation::Field.where(id: fields_to_delete).destroy_all
        i += fields_to_delete.size
        puts "[#{Time.now}] Deleted #{i}/#{n} #{field_name} fields..."
        query = "SELECT f.id FROM dynamic_annotation_fields f WHERE f.field_name = '#{field_name}' ORDER BY f.id ASC LIMIT #{SIZE}"
        result = ActiveRecord::Base.connection.execute(query).to_a
      end

      DynamicAnnotation::FieldInstance.where(name: field_name).destroy_all

      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done. #{n} Archiver.is fields were removed."

      RequestStore.store[:skip_notifications] = false
      RequestStore.store[:skip_clear_cache] = false
      RequestStore.store[:skip_rules] = false
    end
  end
end
