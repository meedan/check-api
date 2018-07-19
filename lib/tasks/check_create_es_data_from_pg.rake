namespace :check do
	# bundle exec rake check:create_es_data_from_pg
	# will create ES from PG
  desc "Create ES data from PG"
  task create_es_data_from_pg: :environment do
  	MediaSearch.delete_index
  	MediaSearch.create_index
  	# Add ES parent
  	[ProjectMedia, ProjectSource].each do |type|
  		type.find_each do |obj|
  			obj.add_elasticsearch_data
        # append nested objects
  			print '.'
  		end
  	end
  	sleep 10
  	# Add ES for annotations (child items)
  	Annotation.find_each do |a|
  		a = a.load
      klass = a.class.name.downcase
      if ['comment', 'tag', 'dynamic'].include?(klass)
    		method = "add_update_elasticsearch_#{klass}"
    		a.send(method)
    		print "."
      end
  	end
  end
end