namespace :check do
  namespace :migrate do
    task update_alegre_stored_project_media: :environment do
      started = Time.now.to_i
      running_bucket = []
      BotUser.alegre_user.team_bot_installations.find_each do |tb|
        last_id = 0 # Rails.cache.read("check:migrate:update_alegre_stored_team_#{tb.team_id}:pm_id") || 0
        # Handle ProjectMedia of Claim, Image, Video and Audio types as all data stored in verification status
        # related to Project Media
        ProjectMedia.where(team_id: tb.team_id).where("project_medias.id > ? ", last_id)
        .where("project_medias.created_at > ?", Time.parse("2020-01-01"))
        .find_in_batches(:batch_size => 2500) do |pms|
          print '.'
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
            print '.'
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
              print '.'
              pm_id = m_mapping[df.m_id]
              pm_data[pm_id]['is_link'] = true
              pm_data[pm_id]['original_title'] = df.value_json['title']
              pm_data[pm_id]['original_description'] = df.value_json['description']
            end
          end
          # loap through ProjectMedia data and send to Alegre when running_bucket.length > 50
          pm_data.each do |k, data|
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
                  Bot::Alegre.item_doc_id(data['project_media'], field)
                )
              end
            end
            if running_bucket.length > 50
              Bot::Alegre.request_api('post', '/text/bulk_similarity/', { documents: running_bucket })
              running_bucket = []
              # log last project media id
              Rails.cache.write("check:migrate:update_alegre_stored_team_#{tb.team_id}:pm_id", k)
            end
          end
        end

      end
      # send latest running_bucket even lenght < 50
      Bot::Alegre.request_api('post', '/text/bulk_similarity/', { documents: running_bucket }) if running_bucket.length > 0
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
