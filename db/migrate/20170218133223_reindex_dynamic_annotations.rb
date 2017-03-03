class ReindexDynamicAnnotations < ActiveRecord::Migration
  def change
    old_index = CONFIG['old_elasticsearch_index']

    unless old_index.blank?
      MediaSearch.delete_index
      MediaSearch.create_index
      n = 0

      [MediaSearch, CommentSearch, TagSearch].each do |klass|
        puts "[ES MIGRATION] Migrating #{klass.name.parameterize} to #{CONFIG['elasticsearch_index']}"

        # Load data from old index
        url = "http://#{CONFIG['elasticsearch_host']}:#{CONFIG['elasticsearch_port']}"
        repository = Elasticsearch::Persistence::Repository.new url: url
        repository.type = klass.name.underscore
        repository.klass = klass
        repository.index = CONFIG['old_elasticsearch_index']
        results = repository.search(query: { match: { annotation_type: klass.name.parameterize } }, size: 10000)

        # Save data in new index
        results.each_with_hit do |obj, hit|
          n += 1
          begin
            options = {}
            options = {parent: hit._parent} unless hit._parent.nil?
            obj.id = hit._id
            obj.save!(options)
            puts "[ES MIGRATION] Migrated #{klass.name} ##{n}"
          rescue Exception => e
            puts "[ES MIGRATION] Could not migrate this item: #{obj.inspect}: #{e.message}"
          end
        end

        puts
      end
    end

    puts "Migration is finished! #{n} items were migrated."
  end
end
