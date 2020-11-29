namespace :check do
  namespace :migrate do
    task reindex_assignments: :environment do
      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil
      started = Time.now.to_i
      errors = 0
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      pmids = []
      total = Assignment.where(assigned_type: ['Annotation', 'Dynamic']).count
      i = 0
      Assignment.where(assigned_type: ['Annotation', 'Dynamic']).find_in_batches(batch_size: 2500) do |as|
        i += 1
        puts "#{i * 2500} / #{total}"
        as.each do |a|
          if a.assigned.annotation_type == 'verification_status'
            pmids << a.assigned.annotated_id.to_i unless pmids.include?(a.assigned.annotated_id.to_i)
          end
        end
      end
      i = 0
      pmids.sort.each_slice(2500) do |ids|
        i += 1
        puts "#{i * 2500} / #{pmids.size}"       
        es_body = []
        pms = ProjectMedia.where(id: ids)
        pms.each do |pm|
          doc_id = pm.get_es_doc_id(pm)
          value = begin
                    Assignment.where(assigned_type: ['Annotation', 'Dynamic'], assigned_id: pm.last_status_obj.id).map(&:user_id).uniq
                  rescue
                    nil
                  end
          next if value.nil?
          fields = { 'assigned_user_ids' => value }
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
