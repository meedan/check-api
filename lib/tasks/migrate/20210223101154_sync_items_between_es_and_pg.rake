namespace :check do
  namespace :migrate do
    task sync_check_items: :environment do
      started = Time.now.to_i
      client = $repository.client
      index_alias = CheckElasticSearchModel.get_index_alias
      options = { index: index_alias }
      sort = [{ annotated_id: { order: :asc } }]
      Team.find_each do |t|
        print '.'
        pg_count = t.project_medias.count
        query = { bool: { must: [ { term: { team_id: { value: t.id } } } ] } }
        es_count = $repository.client.count(index: index_alias, body: { query: query })['count'].to_i
        if es_count > pg_count
          query = { term: { team_id: { value: t.id } } }
          from = 0
          size = 5000
          while from <= es_count  do
            print '.'
            result = $repository.search(query: query, sort: sort, from: from, size: size)
            es_ids = result.collect{ |i| i['annotated_id'] }.uniq
            pg_ids = ProjectMedia.where(id: es_ids).map(&:id)
            diff = es_ids - pg_ids
            if diff.count
              query = { bool: { must: [{ term: { team_id: { value: t.id } } }, { terms: { annotated_id: diff } }] } }
              options[:body] = { query: query }
              client.delete_by_query options
            end
            from += size
          end
        end
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
