namespace :check do
  namespace :migrate do
    task add_smooch_annotations_index: :environment do
      # Read the last annotation id we need to process that was set at migration time.
      last_id = Rails.cache.read('check:migrate:add_smooch_annotations_index:last_id')
      raise "No last_id found in cache for check:migrate:add_smooch_annotations_index! Aborting." if last_id.nil?

      items = Annotation.where(annotation_type: 'smooch').where('annotated_id <= ?', last_id).order(:annotated_id).group_by(&:annotated_id)
      i = 0
      n = items.size

      puts "[#{Time.now}] Starting Smooch annotations indexing: #{n} project medias"
      client = MediaSearch.gateway.client
      index_alias = CheckElasticSearchModel.get_index_alias
      es_body = []
      mapping = {}
      # Loop on each project media with a smooch annotation to invoke its ES indexing.
      items.each do |annotated_id, annotations|
        smooch = annotations.first
        count = annotations.size
        data = { smooch: count, indexable: annotated_id, id: annotated_id }
        options = { keys: [:smooch, :indexable, :id], data: data, op: 'create_or_update' }
        options[:doc_id] = smooch.get_es_doc_id
        mapping[options[:doc_id]] = annotated_id

        # Add the total number of smooch annotations of a project media on ES doc
        key = 'dynamics'
        field_name = 'smooch'
        source = "ctx._source.updated_at=params.updated_at;int s = 0;"+
                 "for (int i = 0; i < ctx._source.#{key}.size(); i++) {"+
                   "if(ctx._source.#{key}[i].#{field_name} != null){"+
                     "ctx._source.#{key}[i].#{field_name} = params.value.#{field_name};s = 1;break;}}"+
                 "if (s == 0) {ctx._source.#{key}.add(params.value)}"
        values = smooch.store_elasticsearch_data(options[:keys], options[:data])
        es_body << { update: { _index: index_alias, _type: 'media_search', _id: options[:doc_id],
                 data: { script: { source: source, params: { value: values, id: values[:id], updated_at: Time.now.utc } } } } }

        i += 1
      end
      response = client.bulk body: es_body
      if response['errors']
        failures = []
        response['items'].select { |i| i.dig('error') }.each do |item|
          update = item['update']
          failures << { annotated_id: mapping[update['_id']],
                        doc_id: update['_id'],
                        status: update['status'],
                        error: update['error']['type']}
        end
      end
      Rails.cache.delete('check:migrate:add_smooch_annotations_index:last_id')
      puts "[#{Time.now}] Indexed Smooch annotations for #{n} project medias"
      unless failures.empty?
        puts "[#{Time.now}] #{failures.size} project medias couldn't be updated:"
        puts failures.map(&:inspect)
      end
    end
  end
end
