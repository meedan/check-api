namespace :check do
  # bundle exec rake check:create_es_data_from_pg
  # will create ES from PG
  desc "Create ES data from PG"
  task create_es_data_from_pg: :environment do
    failed = false
    begin
      MediaSearch.delete_index
      MediaSearch.create_index
      index_pg_data
    rescue Exception => e
      puts "You must delete the existing index or alias [#{CheckElasticSearchModel.get_index_alias}] before running the task."
    end
  end

  def index_pg_data
    # Add ES doc
    require 'sidekiq/testing'
    Sidekiq::Testing.inline! do
      [ProjectMedia, ProjectSource].each do |type|
        type.find_each do |obj|
          obj.add_elasticsearch_data
          print '.'
        end
      end
    end
    sleep 20
    # append nested objects
    failed_items = []
    [ProjectMedia, ProjectSource].each do |type|
      type.find_each do |obj|
        id = Base64.encode64("#{obj.class.name}/#{obj.id}")
        doc = MediaSearch.search(query: { match: { _id: id } }).last
        if doc.nil?
          failed_items << {error: 'Faild to find doc on ES', obj_id: obj.id, obj_class: obj.class.name}
        else
          updated_at = []
          # comments
          comments = obj.annotations('comment')
          doc.comments = comments.collect{|c| {id: c.id, text: c.text}}
          # get maximum updated_at for recent_acitivty sort
          max_updated_at = comments.max_by(&:updated_at)
          updated_at << max_updated_at.updated_at unless max_updated_at.nil?
          if obj.class.name == 'ProjectMedia'
            # status
            doc.verification_status = obj.last_status
            ts = obj.annotations.where(annotation_type: "translation_status").last
            doc.translation_status = ts.load.status unless ts.nil?
            # tags
            tags = obj.get_annotations('tag').map(&:load)
            doc.tags = tags.collect{|t| {id: t.id, tag: t.tag_text}}
            max_updated_at = tags.max_by(&:updated_at)
            updated_at << max_updated_at.updated_at unless max_updated_at.nil?
            # Dynamics
            dynamics = []
            obj.annotations.where("annotation_type LIKE 'task_response%'").find_each do |d|
              d = d.load
              options = d.get_elasticsearch_options_dynamic
              dynamics << d.store_elasticsearch_data(options[:keys], options[:data])
              updated_at << d.updated_at
            end
            doc.dynamics = dynamics
          end
          doc.updated_at = updated_at.max
          begin
            doc.save!
          rescue Exception => e
            failed_items << {error: e, obj_id: obj.id, obj_class: obj.class.name}
          end
        end
        print '.'
      end
    end
    if failed_items.size > 0
      puts "Failed to index #{failed_items.size} items"
      pp failed_items
    end
  end
end
