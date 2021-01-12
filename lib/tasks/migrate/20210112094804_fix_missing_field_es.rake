namespace :check do
  namespace :migrate do
    # bundle exec rake check:migrate:fix_missing_field_es[field]
    task fix_missing_field_es: :environment do |_t, args|
      started = Time.now.to_i
      field_name = args.extras.last
      client = $repository.client
      index_alias = CheckElasticSearchModel.get_index_alias
      Team.find_each do |t|
        print "processing team [#{t.slug}] with id [#{t.id}]...\n"
        query = { bool: { must: [ { term: { team_id: { value: t.id } } } ], must_not: [{ exists: { field: field_name } } ] } }
        result = $repository.search(query: query, size: 10000)
        pm_ids = result.collect{ |i| i['annotated_id'] }.uniq
        ProjectMedia.where(id: pm_ids).find_in_batches(:batch_size => 2500) do |pms|
          m_pm = {}
          pms.collect{ |pm| m_pm[pm.media_id] = pm.id }
          medias_id = pms.map(&:media_id)
          es_body = []
          Media.where(id: medias_id).find_each do |m|
            print '.'
            doc_id = Base64.encode64("ProjectMedia/#{m_pm[m.id]}")
            data = { associated_type: m.type }
            if m.type == 'Claim'
            	data['quote'] = m.quote
            elsif m.type == 'Link'
            	data['title'] = m.metadata['title']
            end
            es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: data } } }
          end
          client.bulk body: es_body unless es_body.blank?
        end
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
