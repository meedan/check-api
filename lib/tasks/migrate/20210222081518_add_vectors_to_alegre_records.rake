namespace :check do
  namespace :migrate do
    desc "Updates ProjectMedia titles and descriptions on alegre's index with vectors"
    task add_vectors_to_alegre_records: :environment do
      started = Time.now.to_i
      running_bucket = []
      log_errors = []
      temp_ids = []
      team_total = BotUser.alegre_user.team_bot_installations.count
      counter = 0
      sent_cases = []
      received_cases = []
      indian_teams = [1793]
      BotUser.alegre_user.team_bot_installations.find_each do |tb|
        if indian_teams.include?(tb.team_id)
          tb.set_alegre_model_in_use = Bot::Alegre::INDIAN_MODEL
        else
          tb.set_alegre_model_in_use = Bot::Alegre.default_model
        end
        tb.save!
        last_id = Rails.cache.read("check:migrate:add_vectors_to_alegre_records#{tb.team_id}:pm_id") || 0
        pm_all_count = ProjectMedia.where(team_id: tb.team_id).where("project_medias.id > ? ", last_id)
        .where("project_medias.created_at > ?", Time.parse("2020-01-01")).count
        total = (pm_all_count/2500.to_f).ceil
        counter += 1
        progressbar = ProgressBar.create(:title => "Update team [#{tb.team_id}]: #{counter}/#{team_total}", :total => total)
        ProjectMedia.where(team_id: tb.team_id).where("project_medias.id > ? ", last_id)
        .where("project_medias.created_at > ?", Time.parse("2020-01-01"))
        .find_in_batches(:batch_size => 2500) do |pms|
          progressbar.increment
          ids = pms.map(&:id)
          # add pm_data to collect the following keys
          # project_media: ProjectMedia Object
          # analysis_title: ProjectMedia analysis title
          # analysis_description: ProjectMedia analysis description
          # origina_title: ProjectMedia analysis title
          # origina_description: ProjectMedia analysis description
          # is_link: Boolean type
          pm_data = {}
          pms.each{ |pm| pm_data[pm.id] = { 'project_media' => pm, 'is_link' => false } }
          DynamicAnnotation::Field.select('dynamic_annotation_fields.id, field_name, value, a.annotated_id as pm_id').where(
            field_name: ['title', 'content'], annotation_type: 'verification_status')
          .joins("INNER JOIN annotations a ON a.id = dynamic_annotation_fields.annotation_id AND a.annotated_type = 'ProjectMedia'")
          .where('a.annotated_id IN (?)', ids).find_each do |df|
            if df.field_name == 'title'
              pm_data[df.pm_id]['analysis_title'] = df.value
            else
              pm_data[df.pm_id]['analysis_description'] = df.value
            end
          end
          # Get metadata for Link types
          # Set title and description for metadata if the ones related to verification_status annotation not exist
          ProjectMedia.where(id: ids).joins("INNER JOIN medias m ON project_medias.media_id = m.id AND m.type = 'Link'")
          .find_in_batches(:batch_size => 2500) do |pms_links|
            m_ids = pms_links.map(&:media_id)
            m_mapping = {} # mapping for media => ProjectMedia
            pms_links.each{ |i| m_mapping[i.media_id] = i.id }
            DynamicAnnotation::Field.select('dynamic_annotation_fields.id, value_json, a.annotated_id as m_id')
            .where(field_name: 'metadata_value', annotation_type: 'metadata')
            .joins("INNER JOIN annotations a ON a.id = dynamic_annotation_fields.annotation_id AND a.annotated_type = 'Media'")
            .where('a.annotated_id IN (?)', m_ids).find_each do |df|
              pm_id = m_mapping[df.m_id]
              pm_data[pm_id]['is_link'] = true
              pm_data[pm_id]['original_title'] = df.value_json['title']
              pm_data[pm_id]['original_description'] = df.value_json['description']
            end
          end
          # loap through ProjectMedia data and send to Alegre when running_bucket.length > 50
          pm_data.each do |k, data|
            temp_ids << k
            ['original_title', 'original_description', 'analysis_title', 'analysis_description'].each do |field|
              field_value = data[field]
              # Replace original values for non link type to be same as analysis values
              if !data['is_link'] && field =~ /^original_/
                new_field = field.gsub('original_', 'analysis_')
                field_value = data[new_field]
              end
              unless field_value.blank?
                running_bucket << Bot::Alegre.send_to_text_similarity_index_package(
                  data['project_media'],
                  field,
                  field_value,
                  Bot::Alegre.item_doc_id(data['project_media'], field),
                  tb.settings[:alegre_model_in_use]
                )
              end
            end
            if running_bucket.length > 500
              running_bucket.collect{|x| sent_cases << x}
              output = Bot::Alegre.request_api('post', '/text/bulk_update_similarity/', { documents: running_bucket })
              output.collect{|x| received_cases << x}
              puts received_cases.length
              if output.class.name == 'Hash' && output['type'] == 'error'
                log_errors << { message: output['data'], ids: temp_ids }
              end
              running_bucket = []
              temp_ids = []
              # log last project media id
              Rails.cache.write("check:migrate:add_vectors_to_alegre_records#{tb.team_id}:pm_id", k)
            end
          end
        end
      end
      # send latest running_bucket even lenght < 50
      running_bucket.collect{|x| sent_cases << x}
      output = Bot::Alegre.request_api('post', '/text/bulk_update_similarity/', { documents: running_bucket }) if running_bucket.length > 0
      output.collect{|x| received_cases << x}
      puts received_cases.length
      if output.class.name == 'Hash' && output['type'] == 'error'
        log_errors << { message: output['data'], ids: temp_ids }
      end
      unless log_errors.empty?
        puts "[#{Time.now}] #{log_errors.size} project medias couldn't be updated:"
        puts log_errors
      end
      f = File.open("sent_documents_vectorization.json", "w")
      f.write(sent_cases.to_json)
      f.close
      f = File.open("received_documents_vectorization.json", "w")
      f.write(received_cases.to_json)
      f.close
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
