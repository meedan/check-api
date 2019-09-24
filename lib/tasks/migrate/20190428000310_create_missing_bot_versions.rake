namespace :check do
  namespace :migrate do
    task create_missing_bot_versions: :environment do
      RequestStore.store[:skip_notifications] = true
      {
        'smooch' => ['smooch', 'smooch_response'],
        'keep' => ['archive_is', 'archive_org', 'pender_archive', 'keep_backup'],
        'alegre' => ['language', 'mt']
      }.each do |bot_identifier, annotation_types|
        bot = BotUser.where(identifier: bot_identifier).last
        ids = Annotation.where(annotation_type: annotation_types).where(annotator_id: bot.id).map(&:id)
        puts "[#{Time.now}] Creating versions for #{ids.size} annotations by #{bot_identifier.capitalize} bot"
        versions = []
        puts "[#{Time.now}] Getting annotations that already have versions"
        vids = []
        i = 0
        Version.where(item_type: 'Dynamic', item_id: ids, whodunnit: bot.id.to_s).find_each do |v|
          i += 1
          print "#{i}\r"
          $stdout.flush
          vids << v.item_id.to_i
        end
        vids.uniq!
        i = 0
        n = Annotation.where(annotation_type: annotation_types, annotator_id: bot.id).count
        Annotation.where(annotation_type: annotation_types, annotator_id: bot.id).find_each do |a|
          i += 1
          print "#{i}/#{n}\r"
          $stdout.flush
          unless vids.include?(a.id)
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
          end
        end
        if versions.size > 0
          puts "[#{Time.now}] Bulk-importing #{versions.size} versions..."
          Version.import(versions, recursive: false, validate: false)
        end
        puts "[#{Time.now}] Done!"
      end
      puts "[#{Time.now}] Done!"
      RequestStore.store[:skip_notifications] = false
    end
  end
end
