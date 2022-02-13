namespace :check do
  namespace :migrate do
    task index_cluster_report_published: :environment do
      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil
      started = Time.now.to_i
      errors = 0
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      pmids = []
      total = Cluster.count
      i = 0
      Cluster.find_in_batches(batch_size: 3000) do |cs|
        i += 1
        puts "#{i * 3000} / #{total}"       
        es_body = []
        cs.each do |c|
          begin
            pm = c.project_media
            doc_id = pm.get_es_doc_id(pm)
            fields = {
              cluster_report_published: (c.get_names_of_teams_that_fact_checked_it.empty? ? 0 : 1)
            }
            es_body << { update: { _index: index_alias, _id: doc_id, data: { doc: fields } } }
          rescue
            errors += 1
          end
        end
        response = client.bulk body: es_body
        puts "[#{Time.now}] Done for batch ##{i}"
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes. Errors: #{errors}"
      ActiveRecord::Base.logger = old_logger
    end
  end
end
