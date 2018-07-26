namespace :check do
	# bundle exec rake check:create_es_data_from_pg
	# will create ES from PG
  desc "Create ES data from PG"
  task create_es_data_from_pg: :environment do
  	MediaSearch.delete_index
  	MediaSearch.create_index
  	# Add ES doc
  	[ProjectMedia, ProjectSource].each do |type|
  		type.find_each do |obj|
  			obj.add_elasticsearch_data
        # append nested objects
  			print '.'
  		end
  	end
  	sleep 20
    [ProjectMedia, ProjectSource].each do |type|
      type.find_each do |obj|
        id = Base64.encode64("#{obj.class.name}/#{obj.id}")
        doc = MediaSearch.find id
        # commentts 
        comments = obj.annotations('comment')
        doc.comments = comments.collect{|c| {id: c.id, text: c.text}}
        if obj.class.name == 'ProjectMedia'
          # status
          doc.verification_status = obj.last_status
          ts = obj.annotations.where(annotation_type: "translation_status").last.load
          doc.translation_status = ts.status
          # tags
          tags = obj.get_annotations('tag').map(&:load)
          doc.tags = tags.collect{|t| {id: t.id, tag: t.tag}}
          # Dynamics
          dynamics = []
          obj.annotations.where("annotation_type LIKE 'task_response%'").find_each do |d|
            d = d.load
            options = d.get_elasticsearch_options_dynamic
            dynamics << d.store_elasticsearch_data(options[:keys], options[:data])
          end
          doc.dynamics = dynamics
        end
        doc.save!
        print '.'
      end
    end
  end
end