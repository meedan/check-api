namespace :check do
  namespace :migrate do
    task fix_elastic_search_project_ids: :environment do
      started = Time.now.to_i
      client = $repository.client
      pmps_all = []
      ProjectMediaProject.select('"project_media_id", array_agg("project_id") as "p_ids"')
      .group(:project_media_id).each do |pmp|
        doc_id =  Base64.encode64("ProjectMedia/#{pmp.project_media_id}")
        pmps_all << { doc_id => pmp.p_ids }
      end

      pmps_all.each_slice(2500).each do |pmps|
        es_body = []
        pmps.each do |pmp|
        	print "."
          doc_id =  pmp.keys.first
          fields = { 'project_id' => pmp[doc_id] }
          es_body << { update: { _index: index_alias, _type: 'media_search', _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
        end
        client.bulk body: es_body unless es_body.blank?
      end
      # catch items with no project
      options = {
        index: CheckElasticSearchModel.get_index_alias,
        type: 'media_search',
      }
      ProjectMedia.joins("LEFT JOIN project_media_projects pmp ON project_medias.id = pmp.project_media_id")
      .where('pmp.id is NULL').find_in_batches(:batch_size => 2500) do |pms|
        print "."
        ids = pms.map(&:id)
        body = {
          script: { source: "ctx._source.project_id = params.ids", params: { ids: [] } },
          query: { terms: { annotated_id: ids } }
        }
        options[:body] = body
        client.update_by_query options
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
