namespace :check do
  namespace :migrate do
    task add_source_to_project_medias: :environment do
      RequestStore.store[:skip_notifications] = true
      started = Time.now.to_i
      client = $repository.client
      index_alias = CheckElasticSearchModel.get_index_alias
      Team.find_each do |t|
        ts_mapping = {} # mapping for TeamId => SourceId
        t.source_ids.collect{ |s| ts_mapping[s] = s}
        puts "Processing items related to team [#{t.slug}]"
        ProjectMedia.where(team_id: t.id, source_id: nil).joins(:media).where('medias.type = ?', 'Link').find_in_batches(batch_size: 2500) do |pms|
          pm_mapping = {} # mapping for ProjectMediaId => MediaId
          as_mapping = {} # mapping for AccountId => SourceId
          ma_mapping = {} # mapping for MediaId => AccountId
          pms.each{ |pm| pm_mapping[pm.id] = pm.media_id}
          Link.where(id: pms.map(&:media_id)).find_in_batches(batch_size: 2500) do |m_all|
            print '.'
            m_all.each{ |m| ma_mapping[m.id] = m.account_id }
            AccountSource.where(account_id: m_all.map(&:account_id)).collect{ |as| as_mapping[as.account_id] = as.source_id }
          end
          # Verify that source already exists in current team otherwise create a new one
          not_existins_sources = as_mapping.values - ts_mapping.values
          Source.where(id: not_existins_sources).find_each do |s|
            puts '.'
            new_source = Source.create_source(s.name, t)
            ts_mapping[s.id] = new_source.id
          end
          es_body = []
          pms.each do |pm|
            source_id = ts_mapping[as_mapping[ma_mapping[pm_mapping[pm.id]]]]
            unless source_id.blank?
              print '.'
              pm.update_columns(source_id: source_id)
              # ES update
              doc_id = Base64.encode64("ProjectMedia/#{pm.id}")
              data = { source_id: source_id }
              es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: data } } }
            end
          end
          client.bulk body: es_body unless es_body.blank?
        end
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
      RequestStore.store[:skip_notifications] = false
    end
  end
end
