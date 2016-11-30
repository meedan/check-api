class MigrateAnnotationsFromEsToPg < ActiveRecord::Migration
  class AnnotationsRepository
    include Elasticsearch::Persistence::Repository

    def initialize(options = {})
      url = "http://#{CONFIG['elasticsearch_host']}:#{CONFIG['elasticsearch_port']}"
      index CONFIG['elasticsearch_index']
      client Elasticsearch::Client.new url: url
    end

    def deserialize(document)
      klass = document['_source']['annotation_type'].camelize.constantize
      obj = klass.new
      document['_source'].each do |key, value|
        obj.send("#{key}=", value)
      end
      obj
    end
  end

  def change
    unless CONFIG['elasticsearch_index'].blank?
      repository = AnnotationsRepository.new
      repository.search(query: { match_all: {} }, size: 10000).to_a.each do |obj|
        # This will call the deserialize method above, that will instantiate an object
        obj.disable_es_callbacks == true
        obj.save!
        puts obj.inspect
      end
    end
  end
end
