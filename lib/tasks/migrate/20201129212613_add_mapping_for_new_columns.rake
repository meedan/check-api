namespace :check do
  namespace :migrate do
    task index_new_columns: :environment do
      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil
      started = Time.now.to_i
      errors = 0
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      pmids = []
      total = ProjectMedia.count
      i = 0
      ProjectMedia.find_in_batches(batch_size: 3000) do |pms|
        i += 1
        puts "#{i * 3000} / #{total}"       
        es_body = []
        pms.each do |pm|
          doc_id = pm.get_es_doc_id(pm)
          report_status = pm.report_status
          media_published_at = pm.media_published_at
          tags_as_sentence = pm.tags_as_sentence
          fields = {
            'report_status' => ['unpublished', 'paused', 'published'].index(report_status),
            'media_published_at' => media_published_at.to_i,
            'tags_as_sentence' => tags_as_sentence.split(', ').size
          }
          es_body << { update: { _index: index_alias, _id: doc_id, data: { doc: fields } } }
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
