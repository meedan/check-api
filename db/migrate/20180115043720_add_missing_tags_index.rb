class AddMissingTagsIndex < ActiveRecord::Migration
  def change
  	ids = Annotation.where(annotation_type: 'tag').map(&:id)
  	unless ids.blank?
  		Tag.where(id: ids).find_each do |t|
        t.add_update_nested_obj('create', 'tags', %w(tag))
  		end
  	end
  end
end
