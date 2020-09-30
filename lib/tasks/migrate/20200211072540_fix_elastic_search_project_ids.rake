namespace :check do
  namespace :migrate do
    task fix_elastic_search_project_ids: :environment do
      started = Time.now.to_i
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      pmps_all = []
      ProjectMediaProject.select('"project_media_id", array_agg("project_id") as "p_ids"')
      .group(:project_media_id).each do |pmp|
        doc_id =  Base64.encode64("ProjectMedia/#{pmp.project_media_id}")
        pmps_all << { doc_id => pmp.p_ids }
      end
      total = (pmps_all.size/2500.to_f).ceil
      progressbar = ProgressBar.create(:title => "Update items belongs to list", :total => total)
      pmps_all.each_slice(2500).each do |pmps|
        progressbar.increment
        es_body = []
        pmps.each do |pmp|
          doc_id =  pmp.keys.first
          fields = { 'project_id' => pmp[doc_id] }
          es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
        end
        client.bulk body: es_body unless es_body.blank?
      end
      # catch items with no project
      count = ProjectMedia.joins("LEFT JOIN project_media_projects pmp ON project_medias.id = pmp.project_media_id")
                .where('pmp.id is NULL').count
      total = (count/2500.to_f).ceil
      progressbar = ProgressBar.create(:title => "Update items with no list", :total => total)
      options = {
        index: CheckElasticSearchModel.get_index_alias,
      }
      ProjectMedia.joins("LEFT JOIN project_media_projects pmp ON project_medias.id = pmp.project_media_id")
      .where('pmp.id is NULL').find_in_batches(:batch_size => 2500) do |pms|
        progressbar.increment
        ids = pms.map(&:id)
        body = {
          script: { source: "ctx._source.project_id = params.ids", params: { ids: [] } },
          query: { terms: { annotated_id: ids } }
        }
        options[:body] = body
        client.update_by_query options
      end
      # Fix archived field
      count = ProjectMedia.where(archived: true).count
      total = (count/2500.to_f).ceil
      progressbar = ProgressBar.create(:title => "Update items with archived = true", :total => total)
      ProjectMedia.where(archived: true).find_in_batches(:batch_size => 2500) do |pms|
        progressbar.increment
        ids = pms.map(&:id)
        body = {
          script: { source: "ctx._source.archived = params.archived", params: { archived: 1 } },
          query: { terms: { annotated_id: ids } }
        }
        options[:body] = body
        client.update_by_query options
      end
      count = ProjectMedia.where(archived: false).count
      total = (count/2500.to_f).ceil
      progressbar = ProgressBar.create(:title => "Update items with archived = false", :total => total)
      ProjectMedia.where(archived: false).find_in_batches(:batch_size => 2500) do |pms|
        progressbar.increment
        ids = pms.map(&:id)
        body = {
          script: { source: "ctx._source.archived = params.archived", params: { archived: 0 } },
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
