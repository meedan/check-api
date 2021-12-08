namespace :check do
  namespace :migrate do
    task set_response_datetime_value: :environment do
      started = Time.now.to_i
      client = $repository.client
      index_alias = CheckElasticSearchModel.get_index_alias
      # Get latest team id
      last_team_id = Rails.cache.read('check:migrate:set_response_datetime_value:team_id') || 0
      Team.where('id > ?', last_team_id).find_each do |team|
        puts "Processing team [#{team.slug}]"
        team.project_medias.find_in_batches(:batch_size => 2500) do |pms|
          es_body = []
          DynamicAnnotation::Field.select('dynamic_annotation_fields.id, value, a2.annotated_id as pm_id')
          .joins("INNER JOIN annotations a ON a.id = dynamic_annotation_fields.annotation_id INNER JOIN annotations a2 ON a2.id = a.annotated_id")
          .where(field_name: 'response_datetime')
          .where('a.annotated_type' => 'Task', 'a2.annotated_type' => 'ProjectMedia', 'a2.annotated_id' => pms.map(&:id))
          .find_in_batches(:batch_size => 2500) do |fields|
            fields.each do |f|
              print '.'
              doc_id = Base64.encode64("ProjectMedia/#{f.pm_id}")
              fields = { 'date_value' => DateTime.parse(f.value).utc }
              es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
            end
          end
          client.bulk body: es_body unless es_body.blank?
        end
        # log last team id
        Rails.cache.write('check:migrate:set_response_datetime_value:team_id', team.id)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
