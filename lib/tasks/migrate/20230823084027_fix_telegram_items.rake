namespace :check do
  namespace :migrate do
    task fix_telegram_items: :environment do
      started = Time.now.to_i
      index_alias = CheckElasticSearchModel.get_index_alias
      id = Team.last.id + 1
      last_team_id = Rails.cache.read('check:migrate:fix_telegram_items:team_id') || id
      # Get smooch user so I can collect tipline items
      smooch_bot = User.where(login: 'smooch').last
      Team.where('id < ?', last_team_id).order(id: :desc).each do |team|
        Team.current = team
        print '.'
        team.project_medias.joins(:media).where('medias.url ~* ?', '^https://(t\.me)')
        .find_in_batches(:batch_size => 1000) do |pms|
          pg_items = []
          es_body = []
          pms.each do |pm|
            # Refresh item to update media provider
            pm.refresh_media=1
            # Update item channel and associated type in both PG & ES
            channel = pm.channel
            channel['others'] ||= []
            unless channel['others'].include?(CheckChannels::ChannelCodes::TELEGRAM)
              print '.'
              channel['others'] << CheckChannels::ChannelCodes::TELEGRAM
              # PG item
              pg_items << { id: pm.id, channel: channel.compact_blank }
              # ES item
              doc_id =  Base64.encode64("ProjectMedia/#{pm.id}")
              fields = { 'associated_type' => 'telegram', 'channel' => channel.values.flatten.uniq.map(&:to_i) }
              es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
            end
          end
          # Update PG items
          ProjectMedia.import(pg_items, recursive: false, validate: false, on_duplicate_key_update: [:channel]) unless pg_items.blank?
          # Update ES items
          $repository.client.bulk body: es_body unless es_body.blank?
          # Migrate title to current media format telegram-team-slug-id
          pm_ids = pms.map(&:id)
          title_fields = []
          tipline_items = ProjectMedia.where(id: pm_ids, user_id: smooch_bot.id).map(&:id)
          Annotation.where(annotation_type: 'verification_status', annotated_type: 'ProjectMedia', annotated_id: tipline_items)
          .find_each do |vs|
            title_fields << {
              annotation_id: vs.id,
              annotation_type: 'verification_status',
              field_type: 'text',
              created_at: vs.created_at,
              updated_at: vs.updated_at,
              value_json: {},
              value: "telegram-#{team.slug}-#{vs.annotated_id}",
              field_name: 'title'
            }
          end
          # Delete existing analysis_title before create new records
          DynamicAnnotation::Field.where(annotation_type: 'verification_status',field_name: 'title')
          .joins('INNER JOIN annotations a ON a.id = dynamic_annotation_fields.annotation_id')
          .where('a.annotated_type = ? AND a.annotated_id IN (?)', 'ProjectMedia', tipline_items).delete_all
          # Import new records
          DynamicAnnotation::Field.import title_fields, validate: false, recursive: false, timestamps: false unless title_fields.blank?
          # Clear title cached field to enforce creating a new one with updated value
          tipline_items.each{ |pm_id| Rails.cache.delete("check_cached_field:ProjectMedia:#{pm_id}:title") }
        end
        Rails.cache.write('check:migrate:fix_telegram_items:team_id', team.id)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end