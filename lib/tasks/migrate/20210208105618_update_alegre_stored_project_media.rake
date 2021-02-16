namespace :check do
  namespace :migrate do
    task update_alegre_stored_project_media: :environment do |_t, args|
      started = Time.now.to_i
      last_id = args.extras.last.to_i rescue 0
      running_bucket = []
      BotUser.alegre_user.team_bot_installations.find_each do |tb|
        # Handle ProjectMedia of Claim, Image, Video and Audio types as all data stored in verification status
        # related to Project Media
        ProjectMedia.where(team_id: tb.team_id).where("project_medias.id > ? ", last_id)
        .where("project_medias.created_at > ?", Time.parse("2020-01-01"))
        .find_in_batches(:batch_size => 2500) do |pms|
          print '.'
          ids = pms.map(&:id)
          # add pm_data to collect the following keys
          # project_media: ProjectMedia Object
          # title: ProjectMedia title
          # description: ProjectMedia description
          # metadata_title: true/false ( True: if title value from metadata and default false)
          # metadata_description: true/false ( True: if description value from metadata and default false)
          pm_data = {}
          pms.each{ |pm| pm_data[pm.id] = { project_media: pm, metadata_title: false, metadata_description: false } }
          DynamicAnnotation::Field.select('dynamic_annotation_fields.id, field_name, value, a.annotated_id as pm_id').where(
            field_name: ['title', 'content'], annotation_type: 'verification_status')
          .joins("INNER JOIN annotations a ON a.id = dynamic_annotation_fields.annotation_id AND a.annotated_type = 'ProjectMedia'")
          .where('a.annotated_id IN (?)', ids).find_each do |df|
            print '.'
            if df.field_name == 'title'
              pm_data[df.pm_id][:title] = df.value
            else
              pm_data[df.pm_id][:description] = df.value
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
              print '.'
              pm_id = m_mapping[df.m_id]
              if pm_data[pm_id][:title].blank?
                pm_data[pm_id][:metadata_title] = true
                pm_data[pm_id][:title] = df.value_json['title']
              end
              if pm_data[pm_id][:description].blank?
                pm_data[pm_id][:metadata_description] = true
                pm_data[pm_id][:description] = df.value_json['description']
              end
            end
          end

          pm_data.each do |_k, data|
            unless data[:title].blank?
              running_bucket << Bot::Alegre.send_to_text_similarity_index_package(
                data[:project_media],
                'original_title',
                data[:title],
                Bot::Alegre.item_doc_id(data[:project_media], 'original_title')
              )
              running_bucket << Bot::Alegre.send_to_text_similarity_index_package(
                data[:project_media],
                'analysis_title',
                data[:title],
                Bot::Alegre.item_doc_id(data[:project_media], 'analysis_title')
              ) unless data[:metadata_title]
            end
            unless data[:description].blank?
              running_bucket << Bot::Alegre.send_to_text_similarity_index_package(
                data[:project_media],
                'original_description',
                data[:description],
                Bot::Alegre.item_doc_id(data[:project_media], 'original_description')
              )
              running_bucket << Bot::Alegre.send_to_text_similarity_index_package(
                data[:project_media],
                'analysis_description',
                data[:description],
                Bot::Alegre.item_doc_id(data[:project_media], 'analysis_description')
              ) unless data[:metadata_description]
            end
          end
          if running_bucket.length > 50
            # Bot::Alegre.request_api('post', '/text/bulk_similarity', {documents: running_bucket})
            running_bucket = []
          end
        end
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
