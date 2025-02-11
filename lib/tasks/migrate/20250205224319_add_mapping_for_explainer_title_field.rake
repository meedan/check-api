namespace :check do
  namespace :migrate do
    task project_media_explainer_title: :environment do
      started = Time.now.to_i
      index_alias = CheckElasticSearchModel.get_index_alias
      skip_pmids = []
      es_body = []
      ExplainerItem.find_each do |raw|
        next if skip_pmids.include?(raw.project_media_id)
        pm = raw.project_media
        doc_id =  Base64.encode64("ProjectMedia/#{pm.id}")
        fields = { 'explainer_title' => pm.explainers_titles }
        es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
        skip_pmids << pm.id
      end
      $repository.client.bulk body: es_body unless es_body.blank?
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end