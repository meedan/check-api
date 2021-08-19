namespace :check do
  namespace :migrate do
    task index_extracted_text: :environment do
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      last_team_id = Rails.cache.read('check:migrate:index_extracted_text:team_id') || 0
      Team.where('id > ?', last_team_id).find_each do |team|
        team.project_medias.find_in_batches(:batch_size => 2500) do |pms|
          es_body = []
          ids = pms.map(&:id)
          Dynamic.where(annotated_id: ids, annotated_type: 'ProjectMedia', annotation_type: 'extracted_text')
          .find_in_batches(:batch_size => 2500) do |annotations|
            print '.'
            annotations.each do |d|
              doc_id = Base64.encode64("ProjectMedia/#{d.annotated_id}")
              fields = { 'extracted_text' => d.data['text']}
              es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
            end
          end
          client.bulk body: es_body unless es_body.blank?
        end
        Rails.cache.write('check:migrate:add_channel_to_project_medias:team_id', team.id)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes. Errors: #{errors}"
    end
  end
end

