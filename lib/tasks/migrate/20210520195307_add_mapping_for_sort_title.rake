namespace :check do
  namespace :migrate do
    task fill_es_sort_title: :environment do
      started = Time.now.to_i
      client = $repository.client
      index_alias = CheckElasticSearchModel.get_index_alias
      sort = [{ annotated_id: { order: :asc } }]
      Team.find_each do |t|
        print '.'
        puts "Processing team [#{t.slug}]"
        query = { term: { team_id: { value: t.id } } }
        search_after = [0]
        while true
          result = $repository.search(query: query, sort: sort, search_after: search_after, size: 2500)
          es_ids = result.collect{ |i| i['annotated_id'] }.uniq
          break if es_ids.empty?
          es_body = []
          result.each do |item|
            print '.'
            doc_id = Base64.encode64("ProjectMedia/#{item['annotated_id']}")
            sort_title = item['analysis_title'].blank? ? item['title'] : item['analysis_title']
            data = { sort_title: sort_title }
            es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: data } } }
          end
          client.bulk body: es_body unless es_body.blank?
          search_after = [es_ids.max]
        end
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
