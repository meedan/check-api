namespace :check do
  namespace :migrate do
    task index_cluster_teams_field: :environment do
      started = Time.now.to_i
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      Cluster.find_in_batches(:batch_size => 2500) do |clusters|
        es_body = []
        clusters.each do |cluster|
          print '.'
          doc_id = Base64.encode64("ProjectMedia/#{cluster.project_media_id}")
          fields = { 'cluster_teams' => cluster.team_names(true).keys }
          es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
        end
        client.bulk body: es_body unless es_body.blank?
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end