namespace :check do
  namespace :migrate do

    # bundle exec rake check:migrate:remove_es_fields['recent_activity,recent_added']
    desc "remove recent_activity and recent_added elasticsearch fields from media doc"
    task remove_es_recent_fields: :environment do
      # Read the last project media id we need to process that was set at migration time.
      last_id = Rails.cache.read('check:migrate:remove_es_recent_fields:last_id')
      raise "No last_id found in cache for check:migrate:remove_es_recent_fields! Aborting." if last_id.nil?

      i = 0
      n = ProjectMedia.count

      puts "[#{Time.now}] Starting removal of fields `recent_activity` and `recent_added`: #{n} project medias"
      client = MediaSearch.gateway.client
      index_alias = CheckElasticSearchModel.get_index_alias
      es_body = []

      ProjectMedia.find_each do |pm|
        doc_id = pm.get_es_doc_id
        source = "ctx._source.updated_at=params.updated_at;ctx._source.remove('recent_added');ctx._source.remove('recent_activity')"
        es_body << { update: { _index: index_alias, _type: 'media_search', _id: doc_id,
                 data: { script: { source: source, params: { updated_at: Time.now.utc } } } } }

        i += 1
        print "#{i}/#{n}\r"
        $stdout.flush
      end

      puts "[#{Time.now}] Calling ElasticSearch..."
      response = client.bulk body: es_body
      puts "[#{Time.now}] Done!"
      puts "[#{Time.now}] Errors? #{response['errors']}"

      Rails.cache.delete('check:migrate:remove_es_recent_fields:last_id')
    end
  end
end
