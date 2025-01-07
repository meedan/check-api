namespace :check do
    namespace :data do
      # bundle exec rake check:data:reindex_explainers
      desc 'Reindex all explainers in the system'
      task :reindex_explainers => [:environment] do
        old_logger = ActiveRecord::Base.logger
        ActiveRecord::Base.logger = nil
  
        errors = []
        current_time = Time.now
        event_id = ENV['EVENT_ID'] || Digest::MD5.hexdigest("reindex_all_explainers_#{current_time.to_i}")
  
        puts "[#{current_time}] Starting reindex of all explainers"
        
        begin
            explainers_query = ProjectMedia.joins("INNER JOIN annotations ON annotations.annotated_id = project_medias.id AND annotations.annotated_type = 'ProjectMedia'")
            .where(annotations: { annotation_type: 'explainer' })

  
          total_count = explainers_query.count
          puts "[#{current_time}] Found #{total_count} explainers to reindex"
  
          explainers_query.find_in_batches(batch_size: 2500) do |batch|
            batch.each do |pm|
              begin
                Bot::Alegre::ALL_TEXT_SIMILARITY_FIELDS.each do |field|
                  field_value = pm.send(field)
                  next if field_value.to_s.empty?
  
                  doc = Bot::Alegre.send_to_text_similarity_index_package(
                    pm,
                    field,
                    field_value,
                    Bot::Alegre.item_doc_id(pm, field)
                  )
  
                  Bot::Alegre.query_async_with_params(doc, Bot::Alegre.get_pm_type(pm))
                end
              rescue StandardError => e
                errors << e
                puts "[#{Time.now}] Error reindexing ProjectMedia with ID #{pm.id}: #{e.message}"
                CheckSentry.notify(e, project_media_id: pm.id)
              end
            end
          end
  
          if errors.any?
            raise Check::ExplainerReindexing::IncompleteRunError.new("Failed to reindex #{errors.length} explainers")
          else
            puts "[#{Time.now}] Successfully reindexed all explainers"
          end
        rescue StandardError => e
          puts "[#{Time.now}] Fatal error during reindexing: #{e.message}"
          raise
        ensure
          ActiveRecord::Base.logger = old_logger
        end
      end
    end
end
