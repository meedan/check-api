namespace :check do
  namespace :migrate do
    task reattribute_annotations_to_bots: :environment do
      RequestStore.store[:skip_notifications] = true
      {
        'smooch' => ['smooch', 'smooch_response'],
        'keep' => ['archive_is', 'archive_org', 'pender_archive', 'keep_backup'],
        'alegre' => ['language', 'mt']
      }.each do |bot_identifier, annotation_types|
        bot = BotUser.where(login: bot_identifier).last
        n = Annotation.where(annotation_type: annotation_types).where(['annotator_id IS NULL OR annotator_id != ?', bot.id]).count
        puts "[#{Time.now}] Creating versions for #{n} annotations by #{bot_identifier.capitalize} bot"
        versions = []
        i = 0
        Annotation.where(annotation_type: annotation_types).where(['annotator_id IS NULL OR annotator_id != ?', bot.id]).find_each do |a|
          i += 1
          versions << Version.new({
            item_type: 'Dynamic',
            item_id: a.id.to_s,
            event: 'update',
            whodunnit: bot.id.to_s,
            object: nil,
            object_changes: { annotator_id: [a.annotator_id, bot.id.to_s] }.to_json,
            created_at: a.created_at,
            meta: nil,
            event_type: 'update_dynamic',
            object_after: a.to_json,
            associated_id: a.annotated_id,
            associated_type: a.annotated_type
          })
          print "#{i}/#{n}\r"
          $stdout.flush
          if i % 10000 == 0
            Version.import versions, recursive: false, validate: false
            versions = []
          end
        end
        Version.import(versions, recursive: false, validate: false) if versions.size > 0
        puts "[#{Time.now}] Done!"
        puts "[#{Time.now}] Attributing #{n} annotations to #{bot_identifier.capitalize} bot"
        Annotation.where(annotation_type: annotation_types).where(['annotator_id IS NULL OR annotator_id != ?', bot.id]).update_all({ annotator_type: 'BotUser', annotator_id: bot.id })
      end
      puts "[#{Time.now}] Done!"
      RequestStore.store[:skip_notifications] = false
    end
  end
end
