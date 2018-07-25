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
        comments = obj.get_annotations('comment').map(&:load)
        doc.comments = comments.collect{|c| {id: c.id, text: c.text}}
        # tags
        tags = obj.get_annotations('tag').map(&:load)
        doc.tags = tags.collect{|t| {id: t.id, tag: t.tag}}
        doc.save!
        # dynamics 
        sleep 2
        obj.annotations.where("annotation_type LIKE 'task_response%'").find_each do |d|
          d = d.load
          d.add_elasticsearch_dynamic
        end
        print '.'
      end
    end
  end
end