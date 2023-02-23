namespace :check do
  namespace :migrate do
    task index_link_associated_type: :environment do
      # This rake task to index source name
      started = Time.now.to_i
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      last_team_id = 0 #Rails.cache.read('check:migrate:index_link_associated_type:team_id') || 0
      Team.where('id > ?', last_team_id).find_each do |team|
        puts "Processing team #{team.slug} ..."
        team.project_medias.joins(:media).where('medias.type = ?', 'Link').find_in_batches(:batch_size => 1000) do |pms|
          es_body = []
          media_mapping = {}
          pms.each{ |pm| media_mapping[pm.media_id] = pm.id }
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
            es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
          end
          client.bulk body: es_body unless es_body.blank?
        end
        Rails.cache.write('check:migrate:index_link_associated_type:team_id', team.id)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
