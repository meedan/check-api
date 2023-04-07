namespace :check do
  namespace :migrate do
    task migrate_tipline_links_title_format: :environment do |_t, args|
      # This rake task to index source name
      started = Time.now.to_i
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      last_team_id = Rails.cache.read('check:migrate:migrate_tipline_links_associated_type:team_id') || 0
      slug = args.extras.last
      team_condition = slug.blank? ? {} : { slug: slug }
      last_team_id = Rails.cache.read('check:project_media:recalculate_cached_field:team_id') || 0
      last_team_id = 0 unless slug.blank?
      # Get smooch user so I can collect tipline items
      smooch_bot = User.where(login: 'smooch').last
      Team.where('id > ?', last_team_id).where(team_condition).find_each do |team|
        puts "Processing team #{team.slug} ..."
        team.project_medias.joins(:media).where('medias.type = ?', 'Link').find_in_batches(:batch_size => 1000) do |pms|
          es_body = []
          media_mapping = {}
          pms.each{ |pm| media_mapping[pm.media_id] = pm.id }
          # Get verification_status annotation so I can do a bulk-import for analysis title
          pm_ids = pms.map(&:id)
          pm_vs_mapping = {}
          tipline_items = ProjectMedia.where(id: pm_ids, user_id: smooch_bot.id).map(&:id)
          Annotation.where(annotation_type: 'verification_status', annotated_type: 'ProjectMedia', annotated_id: tipline_items)
          .find_each do |vs|
            print '.'
            pm_vs_mapping[vs.annotated_id] = {
              annotation_id: vs.id,
              annotation_type: 'verification_status',
              field_type: 'text',
              created_at: vs.created_at,
              updated_at: vs.updated_at,
              value_json: {}
            }
          end
          title_fields = []
          ids = pms.map(&:media_id)
          DynamicAnnotation::Field
          .select('dynamic_annotation_fields.id, dynamic_annotation_fields.value as value, a.annotated_id as media_id')
          .where(field_name: 'metadata_value', annotation_type: 'metadata')
          .joins("INNER JOIN annotations a ON a.id = dynamic_annotation_fields.annotation_id")
          .where('a.annotated_type = ? and a.annotated_id IN (?)', 'Media', ids)
          .find_each do |field|
            print '.'
            pm_id = media_mapping[field.media_id]
            doc_id = Base64.encode64("ProjectMedia/#{pm_id}")
            value = begin JSON.parse(field.value).with_indifferent_access rescue {} end
            provider = value['provider']
            associated_type = ['instagram', 'twitter', 'youtube', 'facebook', 'tiktok'].include?(provider) ? provider : 'weblink'
            fields = { 'associated_type' => associated_type }
            if tipline_items.include?(pm_id)
              analysis_title = "#{associated_type}-#{team.slug}-#{pm_id}"
              fields['analysis_title'] = analysis_title
              # analysis field data
              title_fields << pm_vs_mapping[pm_id].merge({ value: analysis_title, field_name: 'title' }) unless pm_vs_mapping[pm_id].blank?
            end
            es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
          end
          client.bulk body: es_body unless es_body.blank?
          # Delete existing analysis_title before create new records
          DynamicAnnotation::Field.where(annotation_type: 'verification_status',field_name: 'title')
          .joins('INNER JOIN annotations a ON a.id = dynamic_annotation_fields.annotation_id')
          .where('a.annotated_type = ? AND a.annotated_id IN (?)', 'ProjectMedia', tipline_items).delete_all
          # Import new records
          DynamicAnnotation::Field.import title_fields, validate: false, recursive: false, timestamps: false unless title_fields.blank?
          # Clear title cached field to enforce creating a new one with updated value
          tipline_items.each{ |pm_id| Rails.cache.delete("check_cached_field:ProjectMedia:#{pm_id}:title") }
        end
        Rails.cache.write('check:migrate:migrate_tipline_links_associated_type:team_id', team.id)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end

    task migrate_tipline_claims_title_format: :environment do |_t, args|
      # This rake task to index source name
      started = Time.now.to_i
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      last_team_id = Rails.cache.read('check:migrate:migrate_tipline_links_associated_type:team_id') || 0
      slug = args.extras.last
      team_condition = slug.blank? ? {} : { slug: slug }
      last_team_id = Rails.cache.read('check:project_media:recalculate_cached_field:team_id') || 0
      last_team_id = 0 unless slug.blank?
      # Get smooch user so I can collect tipline items
      smooch_bot = User.where(login: 'smooch').last
      Team.where('id > ?', last_team_id).where(team_condition).find_each do |team|
        puts "Processing team #{team.slug} ..."
        team.project_medias.where(user_id: smooch_bot.id).joins(:media).where('medias.type = ?', 'Claim').find_in_batches(:batch_size => 1000) do |pms|
          es_body = []
          title_fields = []
          # Get verification_status annotation so I can do a bulk-import for analysis title
          pm_ids = pms.map(&:id)
          pm_vs_mapping = {}
          Annotation.where(annotation_type: 'verification_status', annotated_type: 'ProjectMedia', annotated_id: pm_ids)
          .find_each do |vs|
            print '.'
            pm_vs_mapping[vs.annotated_id] = {
              annotation_id: vs.id,
              annotation_type: 'verification_status',
              field_type: 'text',
              created_at: vs.created_at,
              updated_at: vs.updated_at,
              field_name: 'title',
              value_json: {}
            }
          end
          pms.each do |raw|
            print '.'
            doc_id = Base64.encode64("ProjectMedia/#{raw.id}")
            analysis_title = "text-#{team.slug}-#{raw.id}"
            fields = { 'analysis_title' => analysis_title }
            # analysis field data
            title_fields << pm_vs_mapping[raw.id].merge({ value: analysis_title }) unless pm_vs_mapping[raw.id].blank?
            es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
          end
          client.bulk body: es_body unless es_body.blank?
          # Delete existing analysis_title before create new records
          DynamicAnnotation::Field.where(annotation_type: 'verification_status',field_name: 'title')
          .joins('INNER JOIN annotations a ON a.id = dynamic_annotation_fields.annotation_id')
          .where('a.annotated_type = ? AND a.annotated_id IN (?)', 'ProjectMedia', pm_ids).delete_all
          # Import new records
          DynamicAnnotation::Field.import title_fields, validate: false, recursive: false, timestamps: false unless title_fields.blank?
          # Clear title cached field to enforce creating a new one with updated value
          pm_ids.each{ |pm_id| Rails.cache.delete("check_cached_field:ProjectMedia:#{pm_id}:title") }
        end
        Rails.cache.write('check:migrate:migrate_tipline_claims_associated_type:team_id', team.id)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end

    task list_analysis_title_for_tipline_items: :environment do |_t, args|
      # This rake task to index source name
      started = Time.now.to_i
      slug = args.extras.last
      team_condition = slug.blank? ? {} : { slug: slug }
      # Get smooch user so I can collect tipline items
      smooch_bot = User.where(login: 'smooch').last
      data_csv = []
      Team.where(team_condition).find_each do |team|
        puts "Processing team #{team.slug} ..."
        # Collect tipline items with FactCheck
        pm_ids = ProjectMedia.where(team_id: team.id)
        .joins('INNER JOIN claim_descriptions cd ON project_medias.id = cd.project_media_id')
        .joins('INNER JOIN fact_checks fc ON cd.id = fc.claim_description_id').map(&:id)
        # Collect tipline items with analysis fields and no FactCheck
        DynamicAnnotation::Field.select('dynamic_annotation_fields.id, dynamic_annotation_fields.value, pm.id as pm_id')
        .where(annotation_type: 'verification_status',field_name: 'title')
        .joins('INNER JOIN annotations a ON a.id = dynamic_annotation_fields.annotation_id')
        .joins('INNER JOIN project_medias pm ON a.annotated_id = pm.id')
        .where('a.annotated_type = ? AND pm.user_id = ?', 'ProjectMedia', smooch_bot.id)
        .where('pm.team_id = ? AND pm.id NOT IN (?)', team.id, pm_ids).find_each do |field|
          print '.'
          data_csv << [field.pm_id, field.value]
        end
      end
      # Export reports with new languages to CSV
      require 'csv'
      file = "#{Rails.root}/public/tipline_title_field_#{slug}_#{Time.now.to_i}.csv"
      headers = ["pm_id", "title"]
      CSV.open(file, 'w', write_headers: true, headers: headers) do |writer|
        data_csv.each do |d|
          writer << d
        end
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
