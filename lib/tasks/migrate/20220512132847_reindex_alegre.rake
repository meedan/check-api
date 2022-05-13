namespace :check do
  namespace :migrate do
    desc "Updates ProjectMedia titles and descriptions on alegre's index"
    task update_alegre_stored_project_media: :environment do
      started = Time.now.to_i
      running_bucket = []
      log_errors = []
      temp_ids = []
      team_total = BotUser.alegre_user.team_bot_installations.count
      counter = 0
      sent_cases = []
      received_cases = []
      BotUser.alegre_user.team_bot_installations.find_each do |tb|
        models = [tb.get_alegre_model_in_use, Bot::Alegre::ELASTICSEARCH_MODEL].compact.uniq
        last_id = Rails.cache.read("check:migrate:update_alegre_stored_team_#{tb.team_id}:pm_id") || 0
        pm_all_count = ProjectMedia.where(team_id: tb.team_id).where("project_medias.id > ? ", last_id)
        .where("project_medias.created_at > ?", Time.parse("2020-01-01")).count
        total = (pm_all_count/2500.to_f).ceil
        counter += 1
        progressbar = ProgressBar.create(:title => "Update team [#{tb.team_id}]: #{counter}/#{team_total}", :total => total)
        ProjectMedia.where(team_id: tb.team_id).where("project_medias.id > ? ", last_id)
        .where("project_medias.created_at > ?", Time.parse("2020-01-01")).includes(claim_description: :fact_check)
        .find_in_batches(:batch_size => 2500) do |pms|
          progressbar.increment
          pms.each do |pm|
            Bot::Alegre::ALL_TEXT_SIMILARITY_FIELDS.each do |field|
              field_value = pm.send(field)
              if !field_value.to_s.empty?
                request_doc = Bot::Alegre.send_to_text_similarity_index_package(
                  pm,
                  field,
                  field_value,
                  Bot::Alegre.item_doc_id(pm, field)
                ).merge(models: models)
                request_doc.delete(:model)
                running_bucket << request_doc
              end
            end
          end
          if running_bucket.length > 500
            running_bucket.each_slice(500) do |bucket_slice|
              bucket_slice.collect{|x| sent_cases << x}
              output = Bot::Alegre.request_api('post', '/text/bulk_similarity/', { documents: bucket_slice })
              output.collect{|x| received_cases << x}
              puts received_cases.length
              if output.class.name == 'Hash' && output['type'] == 'error'
                log_errors << { message: output['data']}
              end
              Rails.cache.write("check:migrate:update_alegre_stored_team_#{tb.team_id}:pm_id", bucket_slice.last[:context][:project_media_id])
            end
            running_bucket = []
          end
        end
      end
      # send latest running_bucket even lenght < 50
      running_bucket.each_slice(500) do |bucket_slice|
        bucket_slice.collect{|x| sent_cases << x}
        output = Bot::Alegre.request_api('post', '/text/bulk_similarity/', { documents: bucket_slice })
        output.collect{|x| received_cases << x}
        puts received_cases.length
        if output.class.name == 'Hash' && output['type'] == 'error'
          log_errors << { message: output['data']}
        end
      end
      unless log_errors.empty?
        puts "[#{Time.now}] #{log_errors.size} project medias couldn't be updated:"
        puts log_errors
      end
      f = File.open("sent_documents.json", "w")
      f.write(sent_cases.to_json)
      f.close
      f = File.open("received_documents.json", "w")
      f.write(received_cases.to_json)
      f.close
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
