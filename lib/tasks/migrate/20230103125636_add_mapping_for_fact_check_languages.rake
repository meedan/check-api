namespace :check do
  namespace :migrate do
    task index_fact_check_languages: :environment do
      started = Time.now.to_i
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      last_team_id = 0 #Rails.cache.read('check:migrate:index_fact_check_languages:team_id') || 0
      Team.where('id > ?', last_team_id).find_each do |team|
        team.project_medias.find_in_batches(:batch_size => 1000) do |pms|
          es_body = []
          ids = pms.map(&:id)
          ProjectMedia.select('project_medias.id as id, fc.language as language')
          .where(id: ids)
          .joins("INNER JOIN claim_descriptions cd ON project_medias.id = cd.project_media_id")
          .joins("INNER JOIN fact_checks fc ON cd.id = fc.claim_description_id")
          .find_in_batches(:batch_size => 1000) do |items|
            print '.'
            items.each do |fc|
              doc_id = Base64.encode64("ProjectMedia/#{fc['id']}")
              fields = { 'fact_check_languages' => [fc['language']] }
              es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
            end
          end
          client.bulk body: es_body unless es_body.blank?
        end
        Rails.cache.write('check:migrate:index_fact_check_languages:team_id', team.id)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
