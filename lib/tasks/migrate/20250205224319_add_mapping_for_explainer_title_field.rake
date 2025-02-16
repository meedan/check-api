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

    task project_media_initiate_fact_check: :environment do
      started = Time.now.to_i
      Team.find_each do |team|
        params = {
          claim_description_content:nil,
          claim_description_context:nil,
          fact_check_title:nil,
          fact_check_summary:nil,
          fact_check_url:nil,
          fact_check_languages:[]
        }
        options = {
          index: CheckElasticSearchModel.get_index_alias,
          conflicts: 'proceed',
          body: {
            script: {
              source: "ctx._source.claim_description_content = params.claim_description_content;ctx._source.claim_description_context = params.claim_description_context;ctx._source.fact_check_title=params.fact_check_title;ctx._source.fact_check_summary=params.fact_check_summary;ctx._source.fact_check_url=params.fact_check_url;ctx._source.fact_check_languages=params.fact_check_languages",
              params: params
            },
            query: { term: { team_id: { value: team.id } } }
          }
        }
        $repository.client.update_by_query options
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end