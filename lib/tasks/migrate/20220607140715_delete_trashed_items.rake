namespace :check do
  namespace :migrate do
    # bundle exec rails check:migrate:delete_trashed_items['2022-07-17']
    task delete_trashed_items: :environment do |_t, args|
      started = Time.now.to_i
      RequestStore.store[:disable_es_callbacks] = true
      client = $repository.client
      index_alias = CheckElasticSearchModel.get_index_alias
      options = { index: index_alias }
      date_arg = args.extras.last
      date_value = date_arg.blank? ? Time.now : DateTime.parse(date_arg)
      interval = CheckConfig.get('empty_trash_interval', 30).to_i
      deleted_date = date_value - interval.days
      # Get latest team id
      last_team_id = Rails.cache.read('check:migrate:delete_trashed_items:team_id') || 0
      Team.where('id > ?', last_team_id).find_each do |team|
        puts "Processing team [#{team.slug}]"
        team.project_medias.where(archived: CheckArchivedFlags::FlagCodes::TRASHED)
        .where('updated_at <= ?', deleted_date)
        .find_in_batches(:batch_size => 1000) do |pms|
          deleted_ids = pms.map(&:id)
          query = { terms: { annotated_id: deleted_ids } }
          options[:body] = { query: query }
          client.delete_by_query options
          pms.each do |pm|
            print '.'
            pm.destroy!
          end
          sleep 10
        end
        # log last team id
        Rails.cache.write('check:migrate:delete_trashed_items:team_id', team.id)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end

    # bundle exec rails check:migrate:delete_spam_items['2022-07-17']
    task delete_spam_items: :environment do |_t, args|
      started = Time.now.to_i
      RequestStore.store[:disable_es_callbacks] = true
      client = $repository.client
      index_alias = CheckElasticSearchModel.get_index_alias
      options = { index: index_alias }
      date_arg = args.extras.last
      date_value = date_arg.blank? ? Time.now : DateTime.parse(date_arg)
      interval = CheckConfig.get('empty_trash_interval', 30).to_i
      deleted_date = date_value - interval.days
      # Get latest team id
      last_team_id = Rails.cache.read('check:migrate:delete_spam_items:team_id') || 0
      Team.where('id > ?', last_team_id).find_each do |team|
        puts "Processing team [#{team.slug}]"
        team.project_medias.where(archived: CheckArchivedFlags::FlagCodes::SPAM, sources_count: 0)
        .find_in_batches(:batch_size => 1000) do |pms|
          ids = pms.map(&:id)
          # Get confirmed items
          target_ids = Relationship.confirmed.where(source_id: ids).map(&:target_id)
          query = { terms: { annotated_id: target_ids } }
          options[:body] = { query: query }
          client.delete_by_query options
          ProjectMedia.where(id: target_ids).each do |pm|
            print '.'
            pm.destroy!
          end
          sleep 10
        end
        # log last team id
        Rails.cache.write('check:migrate:delete_spam_items:team_id', team.id)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end

    # bundle exec rails check:migrate:enqueue_trashed_items_for_delete_forever['2022-07-17']
    task enqueue_trashed_items_for_delete_forever: :environment do |_t, args|
      started = Time.now.to_i
      date_arg = args.extras.last
      date_value = date_arg.blank? ? Time.now : DateTime.parse(date_arg)
      interval = CheckConfig.get('empty_trash_interval', 30).to_i
      deleted_date = date_value - interval.days
      options = { type: 'trash', updated_at: deleted_date }
      # Get latest team id
      last_team_id = Rails.cache.read('check:migrate:enqueue_trashed_items_for_delete_forever:team_id') || 0
      Team.where('id > ?', last_team_id).find_each do |team|
        puts "Processing team [#{team.slug}]"
        team.project_medias.where(archived: CheckArchivedFlags::FlagCodes::TRASHED)
        .where('updated_at <= ?', deleted_date)
        .find_in_batches(:batch_size => 2500) do |pms|
          print '.'
          ids = pms.map(&:id)
          ids.each{ |pm_id| ProjectMediaTrashWorker.perform_in(1.second, pm_id, YAML.dump(options)) }
        end
        # log last team id
        Rails.cache.write('check:migrate:enqueue_trashed_items_for_delete_forever:team_id', team.id)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end