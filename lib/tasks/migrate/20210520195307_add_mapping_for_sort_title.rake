namespace :check do
  namespace :migrate do
    task fill_es_sort_title: :environment do
      started = Time.now.to_i
      client = $repository.client
      index_alias = CheckElasticSearchModel.get_index_alias
      # Get latest team id
      last_team_id = Rails.cache.read('check:migrate:fill_es_sort_title:team_id') || 0
      Team.where('id > ?', last_team_id).find_each do |t|
        puts "Processing team [#{t.slug}]"
        t.project_medias.find_in_batches(:batch_size => 2500) do |pms|
          es_body = []
          pms.each do |pm|
            print '.'
            doc_id = Base64.encode64("ProjectMedia/#{pm.id}")
            data = { title_index: pm.title }
            es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: data } } }
          end
          client.bulk body: es_body unless es_body.blank?
        end
        # log last team id
        Rails.cache.write('check:migrate:fill_es_sort_title:team_id', t.id)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end

    # task to generate file_title for recent added items
    task fill_file_title: :environment do |_t, args|
      date = args.extras.first
      last_team_id = Rails.cache.read('check:migrate:fill_file_title:team_id') || 0
      Team.where('id > ?', last_team_id).find_each do |t|
        created_at = date.blank? ? t.created_at : date.to_datetime
        t.project_medias.joins(:media)
        .where('project_medias.created_at >= ?', created_at)
        .where('medias.type NOT IN (?)', ['Blank', 'Claim', 'Link'])
        .find_in_batches(:batch_size => 2500) do |pms|
          pms.each do |pm|
            print '.'
            pm.analysis = { file_title: pm.title } unless pm.title.blank?
          end
        end
        # log last team id
        Rails.cache.write('check:migrate:fill_file_title:team_id', t.id)
      end
    end
  end
end
