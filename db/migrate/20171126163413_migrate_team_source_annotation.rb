class MigrateTeamSourceAnnotation < ActiveRecord::Migration
  def change
  	[CommentSearch, TagSearch].each do |klass|
	  	results = klass.search(query: { has_parent: { parent_type: "media_search", query: { match: { annotated_type: "ProjectSource" } } } }, size: 10000)
	    results.each_with_hit do |obj, hit|
	      begin
	        options = {}
	        a = Annotation.where(id: hit._id).last
	        unless a.nil?
	          parent = Base64.encode64("TeamSource/#{a.annotated_id}")
	          options = {parent: parent}
	          obj.id = hit._id
	          obj.save!(options)
	          unless hit._parent.nil?
	            obj.delete({parent: hit._parent})
	          end
	        end
	      rescue Exception => e
	        puts "[ES MIGRATION] Could not migrate this item: #{obj.inspect}: #{e.message}"
	      end
	    end
	  end
	  AccountSource.find_each do |as|
	  	as.account.update_elasticsearch_account
	  end
  end
end
