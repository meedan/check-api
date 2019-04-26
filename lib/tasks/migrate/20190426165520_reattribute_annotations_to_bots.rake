namespace :check do
  namespace :migrate do
    task reattribute_annotations_to_bots: :environment do
      {
        'smooch' => ['smooch', 'smooch_response'],
        'keep' => ['archive_is', 'archive_org', 'pender_archive', 'keep_backup'],
        'alegre' => ['language', 'mt']
      }.each do |bot_identifier, annotation_types|
        puts "[#{Time.now}] Attributing annotations to #{bot_identifier.capitalize} bot"
        bot = TeamBot.where(identifier: bot_identifier).last.bot_user
        Annotation.where(annotation_type: annotation_types).update_all({ annotator_type: 'BotUser', annotator_id: bot.id })
      end
      puts "[#{Time.now}] Done!"
    end
  end
end
