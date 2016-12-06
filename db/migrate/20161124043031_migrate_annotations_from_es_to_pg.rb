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
    puts
    unless CONFIG['elasticsearch_index'].blank?
      repository = AnnotationsRepository.new
      repository.search(query: { match_all: {} }, size: 20000).to_a.each do |obj|
        # This will call the deserialize method above, that will instantiate an object
        print '.'
        begin 
          obj.save!
        rescue ActiveRecord::RecordNotFound
          # Related media was not found
          print '?'
        rescue Exception => e
          if e.message == 'Validation failed: Data has already been taken'
            # Duplicated annotation
            print 'D'
          else
            puts "Error: #{e.message}"
            puts obj.inspect
          end
        end
      end
    end
    puts
  end
end
