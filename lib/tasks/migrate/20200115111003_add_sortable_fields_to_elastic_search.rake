namespace :check do
  namespace :migrate do
    # bundle exec rake check:migrate:add_sortable_fields_to_elastic_search[field_a,field_b]
    task add_sortable_fields_to_elastic_search: :environment do |_t, args|
      fields = {}
      args.extras.each{ |field| fields[field] = 0 if ProjectMedia.new.respond_to?(field) }
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      ProjectMedia.find_in_batches(:batch_size => 5000) do |pms|
        es_body = []
        pms.each do |pm|
          print "."
          doc_id = pm.get_es_doc_id(pm)
          data = {}
          fields.each{ |k, _v| data[k] = pm.send(k).to_i }
          es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: data } } }
        end
        client.bulk body: es_body unless es_body.blank?
      end
    end
  end
end
