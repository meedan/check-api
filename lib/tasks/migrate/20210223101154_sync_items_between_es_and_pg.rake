namespace :check do
  namespace :migrate do
    # bundle exec rake check:sync_check_items_es_and_pg[team_slug1, team_slug2, ...]
    task sync_check_items_es_and_pg: :environment do |_t, args|
      started = Time.now.to_i
      slugs = args.extras
      client = $repository.client
      index_alias = CheckElasticSearchModel.get_index_alias
      options = { index: index_alias }
      sort = [{ annotated_id: { order: :asc } }]
      condition = {}
      condition = { slug: slugs } unless slugs.blank?
      Team.where(condition).find_each do |t|
        print '.'
        pg_count = t.project_medias.count
        query = { bool: { must: [ { term: { team_id: { value: t.id } } } ] } }
        es_count = $repository.client.count(index: index_alias, body: { query: query })['count'].to_i
        if es_count > pg_count
          puts "Processing team [#{t.slug}]: [#{es_count}|#{pg_count}]"
          query = { term: { team_id: { value: t.id } } }
          search_after = [0]
          while true
            result = $repository.search(query: query, sort: sort, search_after: search_after, size: 5000)
            es_ids = result.collect{ |i| i['annotated_id'] }.uniq
            break if es_ids.empty?
            pg_ids = ProjectMedia.where(team_id: t.id, id: es_ids).map(&:id)
            diff = es_ids - pg_ids
            if diff.count
              query = { bool: { must: [{ term: { team_id: { value: t.id } } }, { terms: { annotated_id: diff } }] } }
              options[:body] = { query: query }
              client.delete_by_query options
            end
            search_after = [es_ids.max]
          end
        end
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end

    # list all workspaces that have a different count between PG & ES
    task sync_check_items_workspace_lists: :environment do |_t, args|
      slugs = args.extras
      client = $repository.client
      index_alias = CheckElasticSearchModel.get_index_alias
      options = { index: index_alias }
      sort = [{ annotated_id: { order: :asc } }]
      condition = {}
      condition = { slug: slugs } unless slugs.blank?
      logs = []
      Team.where(condition).find_each do |t|
        print '.'
        pg_count = t.project_medias.count
        query = { bool: { must: [ { term: { team_id: { value: t.id } } } ] } }
        es_count = $repository.client.count(index: index_alias, body: { query: query })['count'].to_i
        logs << {id: t.id, slug: t.slug, pg_count: pg_count, es_count: es_count} if es_count > pg_count
      end
      puts "Print wrokspace with different items in PG & ES"
      pp logs
    end
  end
end
