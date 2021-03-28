namespace :check do
  namespace :migrate do
    task add_url_to_elastic_search: :environment do
      started = Time.now.to_i
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      ProjectMedia.select('project_medias.id AS id, medias.url AS media_url').joins(:media).where('medias.type = ?', 'Link').find_in_batches(:batch_size => 5000) do |pms|
        print '.'
        es_body = []
        pms.each do |pm|
          doc_id =  Base64.encode64("ProjectMedia/#{pm.id}")
          fields = { 'url' => pm.media_url }
          es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
        end
        client.bulk body: es_body unless es_body.blank?
      end
      minutes = (Time.now.to_i - started) / 60
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
