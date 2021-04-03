namespace :check do
  namespace :migrate do
    task add_parent_id_to_elastic_search: :environment do
      started = Time.now.to_i
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      # set parent_id = ProjectMedia.id
      ProjectMedia.find_in_batches(:batch_size => 5000) do |pms|
        print '.'
        es_body = []
        pms.each do |pm|
          doc_id =  Base64.encode64("ProjectMedia/#{pm.id}")
          fields = { 'parent_id' => pm.id }
          es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
        end
        client.bulk body: es_body unless es_body.blank?
      end
      # Update project_id based on relation
      relationship_types = [Relationship.confirmed_type, Relationship.suggested_type]
      Relationship.where(relationship_type: relationship_types).find_in_batches(:batch_size => 5000) do |relations|
        print '.'
        es_body = []
        relations.each do |relation|
          doc_id =  Base64.encode64("ProjectMedia/#{relation.target_id}")
          fields = { 'parent_id' => relation.source_id }
          es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
        end
        client.bulk body: es_body unless es_body.blank?
      end
      minutes = (Time.now.to_i - started) / 60
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
