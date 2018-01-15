class AddMissingTagsIndex < ActiveRecord::Migration
  def change
  	t_ids = Annotation.where(annotation_type: 'tag').map(&:id)
  	ts_ids = TagSearch.search(query: { match_all: {  } }).results.map(&:_id)
  	ids = t_ids - ts_ids.map(&:to_i) 
  	unless ids.blank?
  		Tag.where(id: ids).find_each do |t|
  			t.add_update_media_search_child('tag_search', %w(tag full_tag))
  		end
  	end
  end
end
