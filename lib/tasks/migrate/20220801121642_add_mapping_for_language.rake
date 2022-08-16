namespace :check do
  namespace :migrate do
    task index_item_language: :environment do
      started = Time.now.to_i
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      last_team_id = Rails.cache.read('check:migrate:index_language:team_id') || 0
      Team.where('id > ?', last_team_id).find_each do |team|
        team.project_medias.find_in_batches(:batch_size => 2500) do |pms|
          es_body = []
          ids = pms.map(&:id)
          ProjectMedia.select('project_medias.id, f.value as value')
          .where(id: ids)
          .joins("INNER JOIN annotations a ON a.annotated_id = project_medias.id AND a.annotation_type = 'language'")
          .joins("INNER JOIN  dynamic_annotation_fields f ON f.annotation_id = a.id AND f.field_name = 'language'")
          .find_in_batches(:batch_size => 2500) do |items|
            print '.'
            items.each do |f|
              doc_id = Base64.encode64("ProjectMedia/#{f['id']}")
              value = begin JSON.parse(f['value']) rescue f['value'] end
              fields = { 'item_language' => value }
              es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
            end
          end
          client.bulk body: es_body unless es_body.blank?
        end
        Rails.cache.write('check:migrate:index_language:team_id', team.id)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
