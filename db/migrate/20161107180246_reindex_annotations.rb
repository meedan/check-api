# Before running this migration, change your elasticsearch_index configuration to old_elasticsearch_index, define a new index for
# elasticsearch_index and run this.

class ReindexAnnotations < ActiveRecord::Migration
  def change
    old_index = CONFIG['old_elasticsearch_index']

    unless old_index.blank?
      Annotation.delete_index
      Annotation.create_index
      n = 0

      classes = [Comment, Embed, Flag, Tag]
      classes << Status unless defined?(Status).nil?

      classes.each do |klass|
        puts "[ANNOTATIONS MIGRATION] Migrating #{klass.name.parameterize} to #{CONFIG['elasticsearch_index']}"

        # Load data from old index
        url = "http://#{CONFIG['elasticsearch_host']}:#{CONFIG['elasticsearch_port']}"
        repository = Elasticsearch::Persistence::Repository.new url: url
        repository.type = 'annotation'
        repository.klass = klass
        repository.index = CONFIG['old_elasticsearch_index']
        data = repository.search(query: { match: { annotation_type: klass.name.parameterize } }, size: 10000).to_a
        
        # Save data in new index
        data.each do |annotation|
          n += 1
          begin
            annotation.save
            puts "[ANNOTATIONS MIGRATION] Migrated annotation ##{n}"
          rescue Exception => e
            puts "[ANNOTATIONS MIGRATION] Could not migrate this annotation: #{annotation.inspect}: #{e.message}"
          end
        end

        puts
      end
    end

    puts "Migration is finished! #{n} annotations were migrated."
  end
end
