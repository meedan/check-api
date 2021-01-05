namespace :check do
  namespace :migrate do
    task fix_requests_count_unconfirmed_medias: :environment do
      started = Time.now.to_i
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      ProjectMedia.select('project_medias.id, count(project_medias.id) as c')
      .where(archived: CheckArchivedFlags::FlagCodes::UNCONFIRMED)
      .joins("INNER JOIN annotations a on a.annotated_id = project_medias.id AND a.annotation_type = 'smooch'")
      .group('project_medias.id').find_in_batches(batch_size: 2500) do |pms|
        pms.each do |pm|
          print '.'
          Rails.cache.write("check_cached_field:ProjectMedia:#{pm.id}:requests_count", pm.c)
        end
        es_body = []
        ProjectMedia.where(id: pms.map(&:id)).find_each do |pm|
          print '.'
          demand = pm.demand(true)
          doc_id = Base64.encode64("ProjectMedia/#{pm.id}")
          fields = { 'demand' => demand.to_i }
          es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
        end
        client.bulk body: es_body unless es_body.blank?
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
