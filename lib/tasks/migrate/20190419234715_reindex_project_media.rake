namespace :check do
  namespace :migrate do
    task reindex_project_media: :environment do
      client = MediaSearch.gateway.client
      index_alias = CheckElasticSearchModel.get_index_alias

      puts "[#{Time.now}] Re-indexing project medias and project sources"
      puts "[#{Time.now}] Looking for unindexed content..."
      n = ProjectMedia.count
      i = 0
      ProjectMedia.find_each do |model|
        i += 1
        puts "[#{Time.now}] #{i}/#{n}: Looking for ES document for project media with id #{model.id}"
        model.create_elasticsearch_doc_bg(nil) unless client.exists?(index: index_alias, type: 'media_search', id: model.get_es_doc_id)
      end
      n = ProjectSource.count
      i = 0
      ProjectSource.find_each do |model|
        i += 1
        puts "[#{Time.now}] #{i}/#{n}: Looking for ES document for project source with id #{model.id}"
        model.create_elasticsearch_doc_bg(nil) unless client.exists?(index: index_alias, type: 'media_search', id: model.get_es_doc_id)
      end

      sleep 60

      n = ProjectMedia.count
      puts "[#{Time.now}] Re-indexing #{n} project medias"
      es_body = []
      i = 0

      ProjectMedia.includes(:project).find_each do |model|
        i += 1
        puts "[#{Time.now}] #{i}/#{n}: Getting data for project media #{model.id}"
        keys = %w(project_id team_id recent_added recent_activity archived inactive)
        data = {
          'project_id' => model.project_id,
          'team_id' => model.project&.team_id&.to_i,
          'recent_added' => model.created_at.to_i,
          'recent_activity' => model.updated_at.to_i,
          'archived' => model.archived.to_i,
          'inactive' => model.inactive.to_i,
        }
        options = { keys: keys, data: data, parent: model, obj: model, doc_id: model.get_es_doc_id(model) }
        fields = { 'updated_at' => model.updated_at.utc }
        options[:keys].each{ |k| fields[k] = data[k] if !data[k].blank? }
        es_body << { update: { _index: index_alias, _type: 'media_search', _id: options[:doc_id], data: { doc: fields } } }
      end

      puts "[#{Time.now}] Calling ElasticSearch..."      
      response = client.bulk body: es_body
      puts "[#{Time.now}] Done!"
      puts "[#{Time.now}] Errors? #{response['errors']}"
 
      n = ProjectSource.count
      puts "[#{Time.now}] Re-indexing #{n} project sources"
      es_body = []
      i = 0
      ProjectSource.includes(:project).find_each do |model|
        i += 1
        puts "[#{Time.now}] #{i}/#{n}: Getting data for project source #{model.id}"
        keys = %w(project_id team_id recent_added recent_activity)
        data = {
          'project_id' => model.project_id,
          'team_id' => model.project&.team_id&.to_i,
          'recent_added' => model.created_at.to_i,
          'recent_activity' => model.updated_at.to_i,
        }
        options = { keys: keys, data: data, parent: model, obj: model, doc_id: model.get_es_doc_id(model) }
        fields = { 'updated_at' => model.updated_at.utc }
        options[:keys].each{ |k| fields[k] = data[k] if !data[k].blank? }
        es_body << { update: { _index: index_alias, _type: 'media_search', _id: options[:doc_id], data: { doc: fields } } }
      end

      puts "[#{Time.now}] Calling ElasticSearch..."      
      response = client.bulk body: es_body
      puts "[#{Time.now}] Done!"
      puts "[#{Time.now}] Errors? #{response['errors']}"
    end
  end
end
