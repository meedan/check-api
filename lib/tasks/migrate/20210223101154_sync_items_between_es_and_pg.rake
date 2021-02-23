namespace :check do
  namespace :migrate do
    task sync_check_items: :environment do
      started = Time.now.to_i
      client = $repository.client
      index_alias = CheckElasticSearchModel.get_index_alias
      options = { index: index_alias }
      Team.find_each do |t|
        print '.'
        pg_count = t.project_medias.count
        query = { bool: { must: [ { term: { team_id: { value: t.id } } } ] } }
        es_count = $repository.client.count(index: index_alias, body: { query: query })['count'].to_i
        if es_count > pg_count
          pg_ids = t.project_medias.map(&:id)
          options[:body] = {
            query: { bool: { must: [ { term: { team_id: { value: t.id } } } ], must_not: [ { terms: { annotated_id: pg_ids } } ] } }
          }
          client.delete_by_query options
        end
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
